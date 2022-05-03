import sys
import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3" 
import numpy as np
sys.path.insert(0, '../../MSA-HMM')
import msa_hmm

#given a fasta file, creates a fragmentary version by drawing random sequences and random fragment lengths

file = sys.argv[1]
ref_file = sys.argv[2]
out_file = sys.argv[3]
out_ref_file = sys.argv[4]

# fragmentary parameters
mean_len_percentage = 0.25
fragmentary_seqs = 0.5
fragment_length_deviation = 15


fasta = msa_hmm.fasta.Fasta(file, gaps=False, contains_lower_case=True)
ref_fasta = msa_hmm.fasta.Fasta(ref_file, gaps=True, contains_lower_case=True)
mean_fragment_len = np.mean(fasta.seq_lens) * mean_len_percentage
n_frag = int(fasta.num_seq * fragmentary_seqs)
lens = np.copy(fasta.seq_lens)
fragment_seqs_ind = np.random.choice(np.arange(fasta.num_seq), replace=False, size=n_frag)
lens[fragment_seqs_ind] = np.random.normal(mean_fragment_len, fragment_length_deviation, size=n_frag)
lens = np.maximum(lens, 16)
lens = np.minimum(lens, fasta.seq_lens)

out = open(out_file, "w")
out_ref = open(out_ref_file, "w")
frag_msa = np.copy(ref_fasta.ref_seq)

gap_symbol = msa_hmm.fasta.s-1
    
for i, seq_id in enumerate(fasta.seq_ids):
    target_length = int(lens[i])
    seq = fasta.aminoacid_seq_str(i)
    pos = np.random.choice(np.arange(fasta.seq_lens[i]-target_length+1), size=1)[0]
    seq = seq[pos:pos+target_length]
    out.write(">"+seq_id+"\n")
    out.write(seq+"\n")
    try:
        ref_i = ref_fasta.seq_ids.index(seq_id)
    except ValueError:
        ref_i = -1
    if ref_i != -1:
        s = ref_fasta.starting_pos[ref_i]
        membership_targets = ref_fasta.membership_targets[s:s+ref_fasta.seq_lens[ref_i]]
        if pos > 0:
            frag_msa[ref_i, :membership_targets[pos]] = gap_symbol
        if pos+target_length < fasta.seq_lens[i]:
            frag_msa[ref_i, membership_targets[pos+target_length]:] = gap_symbol

frag_msa = frag_msa[:, ~np.all(frag_msa == gap_symbol, axis=0)]
        
alphabet = msa_hmm.fasta.alphabet[:-1] + ["-"]
for i, seq_id in enumerate(ref_fasta.seq_ids):
    aligned_seq = "" 
    for j in frag_msa[i]:
        aligned_seq += alphabet[j]
    out_ref.write(">"+seq_id+"\n")
    out_ref.write(aligned_seq+"\n")
    
        
out.close()
out_ref.close()