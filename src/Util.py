import numpy as np
import os
import tensorflow as tf
from learnMSA import msa_hmm
from pathlib import Path
import time
import pandas as pd
import sys

def convert_time(total_secs):
    secs, mins = np.modf(total_secs/60.)
    mins = int(mins)
    secs *= 60.
    return mins, secs

def make_dirs(name):
    results_path = "results/"+name
    Path(results_path+"/logs/").mkdir(parents=True, exist_ok=True)
    Path(results_path+"/times/").mkdir(parents=True, exist_ok=True)
    Path(results_path+"/alignments/").mkdir(parents=True, exist_ok=True)
    Path(results_path+"/models/").mkdir(parents=True, exist_ok=True)
    return results_path
    
def run_tests(runner_func, name, datasets=["homfam"], num_models=10, data_path="data/"):
    results_path = make_dirs(name)
    stdout = sys.stdout
    for dataset in datasets:
        for file in os.listdir(data_path+dataset+"/train"):
            if file.endswith(".fasta"):
                family = ".".join(file.split(".")[:-1])
                train_file = data_path + dataset+"/train/" + file
                ref_file = data_path + dataset+"/refs/" + family + ".ref"
                log_filepath = results_path+"/logs/" + family + ".log"
                out_file = results_path+"/alignments/" + file
                if os.path.exists(out_file):
                    continue
                sys.stdout = open(log_filepath, "w")
                t = time.time()
                alignment_model, sp = runner_func(train_file, 
                                        ref_file, 
                                        out_file,
                                        msa_hmm.config.make_default(num_models))
                score_filepath = results_path + "/" + name + "." + dataset + ".out"
                with open(score_filepath, "a") as out_file:
                    out_file.write(f"{family} {sp} 0 0 0 0\n")
                aln_mins, aln_secs = convert_time(time.time() - t)
                sys.stdout.close()
                sys.stdout = stdout
                time_filepath = results_path+"/times/"+family+".time.txt"
                with open(time_filepath, "w") as time_file:
                    time_file.write(f"real\t{aln_mins}m{aln_secs}s\n") 
                alignment_model.write_models_to_file(results_path+"/models/"+family)
                
def realign(model_selection_criterion, name, datasets=["homfam"], verbose=True, data_path="data/"):
    model_path = "results/"+name+"/models/"
    msa_path = "results/"+name+"/alignments/"
    for dataset in datasets:
        for file in os.listdir(data_path+dataset+"/train"):
            if file.endswith(".fasta"):
                family = ".".join(file.split(".")[:-1])
                if verbose:
                    print(family)
                am = msa_hmm.AlignmentModel.load_models_from_file(model_path+family)
                best_model = msa_hmm.align.select_model(am, model_selection_criterion, verbose=verbose)
                am.to_file(msa_path+file, best_model)
                
def runner_func(train_file, ref_file, out_file, config):
    return msa_hmm.align.run_learnMSA(train_file,
                                               out_file,
                                                  config, 
                                                  ref_filename=ref_file, 
                                                  verbose=True)

def get_df(name, dataset, scale=False, results_path="results/"):
    df = pd.read_csv(results_path+f"{name}/{name}.{dataset}.out", sep=" ", header=None)
    df.index = df[0]
    if scale:
        df *= 100
    return df

def get_score(name, dataset):
    return get_df(name, dataset)[1].mean()

def compare(name1, name2, dataset, scale1=False, scale2=False, results_path="results/"):
    df1 = get_df(name1, dataset, scale1, results_path)[1]
    df2 = get_df(name2, dataset, scale2, results_path)[1]
    return (df1-df2).sort_values()
    

#a simple "pseudocount" prior that penalizes all probabilities with the same alpha
#if categorical==True, the prior is a Dirichlet distribution over the k categories 
#otherwise, k Dirichlet's over Bernoulli distributions
class PseudoCountPrior():
    def __init__(self, alpha, insertions=False, categorical=True):
        self.alpha = alpha
        self.categorical = categorical
        self.insertions = insertions
        
    def load(self, dtype):
        pass
        
    def __call__(self, B, lengths):
        """Computes log pdf values for each match state.
        Args:
        B: A stack of k emission matrices. Shape: (k, q, s)
        Returns:
        A tensor with the log pdf values of the prior. Shape: (k, max_model_length)
        """
        max_model_length = tf.reduce_max(lengths)
        if self.insertions:
            B = B[:,:-1,:-1]
        else:
            B = B[:,1:max_model_length+1,:-1]
        prior = tf.math.log(B)
        prior = tf.reduce_sum(self.alpha * prior, -1) 
        #zero padding for non match states
        prior *= tf.cast(tf.sequence_mask(lengths), B.dtype)
        return prior
    
class ReduceMultinomialPrior():
    def __init__(self, num_rate_matrices, alpha, insertions=False, categorical=True):
        self.num_rate_matrices = num_rate_matrices
        self.pseudo_count_prior = PseudoCountPrior(alpha, insertions, categorical)
        self.amino_prior = msa_hmm.priors.AminoAcidPrior()
        
    def load(self, dtype):
        self.amino_prior.load(dtype)
        
    def __call__(self, B, lengths):
        return (self.pseudo_count_prior(B[:,:,:self.num_rate_matrices+1], lengths) 
                + self.amino_prior(B[:,:,self.num_rate_matrices+1:], lengths))
    
    
class ReduceMultinomialEmissionInitializer(tf.keras.initializers.Initializer):

    def __init__(self, num_rate_matrices):
        self.n = num_rate_matrices
        self.multinomial_init = msa_hmm.initializers.ConstantInitializer(0.)
        self.amino_initializer = msa_hmm.initializers.make_default_emission_init()

    def __call__(self, shape, dtype=None, **kwargs):
        assert len(shape) == 2, "ReduceMultinomialEmissionInitializer only supports 2D shapes."
        m = self.multinomial_init((shape[0], self.n), dtype, **kwargs)
        a = self.amino_initializer((shape[0], shape[1]-self.n), dtype, **kwargs)
        return tf.concat([m, a], axis=-1)
        
    def __repr__(self):
        return f"ReduceMultinomialEmissionInitializer()"
    
    
class ReduceMultinomialInsertionInitializer(tf.keras.initializers.Initializer):

    def __init__(self, num_rate_matrices):
        self.n = num_rate_matrices
        self.multinomial_init = msa_hmm.initializers.ConstantInitializer(0.)
        self.amino_initializer = msa_hmm.initializers.make_default_insertion_init()

    def __call__(self, shape, dtype=None, **kwargs):
        m = self.multinomial_init((self.n), dtype, **kwargs)
        a = self.amino_initializer((shape[0]-self.n), dtype, **kwargs)
        return tf.concat([m, a], axis=0)
        
    def __repr__(self):
        return f"ReduceMultinomialEmissionInitializer()"
    

class ReduceMultinomialEmitter(msa_hmm.emit.ProfileHMMEmitter):
    def __init__(self, 
                 num_models,
                 num_rate_matrices,
                 alpha,
                 emission_init = None,
                 insertion_init = None,
                 prior = None,
                 frozen_insertions = True):
        if emission_init is None:
            emission_init = [ReduceMultinomialEmissionInitializer(num_rate_matrices)
                                                            for _ in range(num_models)]
        if insertion_init is None:
            insertion_init = [ReduceMultinomialInsertionInitializer(num_rate_matrices)
                                                            for _ in range(num_models)]
        if prior is None:
            prior = ReduceMultinomialPrior(num_rate_matrices, alpha)
        super(ReduceMultinomialEmitter, self).__init__(emission_init, 
                                                       insertion_init, 
                                                       prior, 
                                                       frozen_insertions)
        self.num_models = num_models
        self.num_rate_matrices = num_rate_matrices
        self.alpha = alpha
        
    def build(self, input_shape):
        assert input_shape[-1] % self.num_rate_matrices == 0
        self.s = int(input_shape[-1] / self.num_rate_matrices)
        input_shape = list(input_shape)[:-1]+[self.num_rate_matrices + self.s]
        super(ReduceMultinomialEmitter, self).build(input_shape)
        
    def make_emission_matrix(self, em, ins, length):
        em_multinomial, em_amino = em[:,:self.num_rate_matrices], em[:,self.num_rate_matrices:]
        ins_multinomial, ins_amino = ins[:self.num_rate_matrices], ins[self.num_rate_matrices:]
        B_multinomial = super(ReduceMultinomialEmitter, self).make_emission_matrix(em_multinomial, ins_multinomial, length)
        B_amino = super(ReduceMultinomialEmitter, self).make_emission_matrix(em_amino, ins_amino, length)
        return tf.concat([B_multinomial, B_amino], axis=-1)
    
    def call(self, inputs):
        """ Emission function that models a 2-stage random experiment where one of 
            m rate matrices is selected under a learned multinomial distribution per match state. 
            Args:
                inputs: Stacked ancestral probabilities. Shape: (k, b, m*(s+1))
        """
        inputs = tf.reshape(inputs, (tf.shape(inputs)[0], tf.shape(inputs)[1], self.num_rate_matrices, self.s))
        B_multinomial = self.B[:,:,:self.num_rate_matrices]
        B_terminal = tf.expand_dims(self.B[:,:,self.num_rate_matrices], 1)
        B_amino = self.B[:,:,self.num_rate_matrices+1:]
        # reduce the alphabet dimension first for memory efficiency
        emission_prob = tf.einsum("kqs,kbms->kbqm", B_amino, inputs)
        multinomial_emission_prob = tf.einsum("kbqm,kqm->kbq", emission_prob, B_multinomial)
        multinomial_emission_prob += inputs[:,:,0,-1:] * B_terminal
        return multinomial_emission_prob
    
    # for plotting
    def make_B_amino(self):
        B = self.make_B()
        return B[:,:,self.num_rate_matrices+1:]
    
    def duplicate(self, model_indices=None):
        if model_indices is None:
            model_indices = range(len(self.emission_init))
        sub_emission_init = [tf.constant_initializer(self.emission_kernel[i].numpy()) for i in model_indices]
        sub_insertion_init = [tf.constant_initializer(self.insertion_kernel[i].numpy()) for i in model_indices]
        emitter_copy = ReduceMultinomialEmitter(
                             self.num_models,
                             self.num_rate_matrices,
                             self.alpha,
                             emission_init = sub_emission_init,
                             insertion_init = sub_insertion_init,
                             prior = self.prior,
                             frozen_insertions = self.frozen_insertions) 
        return emitter_copy
    
    
    
def get_encoder_weights(keep_tau, tau_init):
    def _extract_encoder_weights_callback(encoder_model):
        layer_names = [l.name for l in encoder_model.layers]
        for i,n in enumerate(layer_names):
            if "anc_probs_layer" in n:
                break
        anc_probs_layer = encoder_model.layers[i]
        for w in anc_probs_layer.weights:
            if "tau_kernel" in w.name:
                tau_kernel = w
            elif "exchangeability_kernel" in w.name:
                exchangeability_kernel = w
            elif "per_matrix_rates_kernel" in w.name:
                matrix_rates_kernel = w
            elif "equilibrium_kernel" in w.name:
                equilibrium_kernel = w
        if not keep_tau:
            tau_kernel = tf.constant(tau_init)
        if anc_probs_layer.per_matrix_rate:
            return [msa_hmm.initializers.ConstantInitializer(tau_kernel.numpy()), 
                    msa_hmm.initializers.ConstantInitializer(exchangeability_kernel.numpy()), 
                    msa_hmm.initializers.ConstantInitializer(equilibrium_kernel.numpy()),
                    msa_hmm.initializers.ConstantInitializer(matrix_rates_kernel.numpy())]
        else:
            return [msa_hmm.initializers.ConstantInitializer(tau_kernel.numpy()),
                    msa_hmm.initializers.ConstantInitializer(exchangeability_kernel.numpy()),
                    msa_hmm.initializers.ConstantInitializer(equilibrium_kernel.numpy())]
    return _extract_encoder_weights_callback