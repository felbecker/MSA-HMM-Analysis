import sys
import os
import numpy as np
sys.path.insert(0, '../../MSA-HMM')
from msa_hmm import fasta

#given a fasta file, creates a fragmentary version by drawing random sequences and random fragment lengths

file = sys.argv[1]
ref_file = sys.argv[2]
out_file = sys.argv[3]
out_ref_file = sys.argv[4]

# fragmentary parameters
mean_len_percentage = 0.25
fragmentary_seqs = 0.5
fragment_length_deviation = 15


fasta_file = fasta.Fasta(file, gaps=False, contains_lower_case=True)
ref_fasta = fasta.Fasta(ref_file, gaps=True, contains_lower_case=True)
mean_fragment_len = np.mean(fasta_file.seq_lens) * mean_len_percentage
n_frag = int(fasta_file.num_seq * fragmentary_seqs)
lens = np.copy(fasta_file.seq_lens)
fragment_seqs_ind = np.random.choice(np.arange(fasta_file.num_seq), replace=False, size=n_frag)
lens[fragment_seqs_ind] = np.random.normal(mean_fragment_len, fragment_length_deviation, size=n_frag)
lens = np.maximum(lens, 16)
lens = np.minimum(lens, fasta_file.seq_lens)

out = open(out_file, "w")
out_ref = open(out_ref_file, "w")
frag_msa = np.copy(ref_fasta.ref_seq)

gap_symbol = fasta.s-1
    
for i, seq_id in enumerate(fasta_file.seq_ids):
    target_length = int(lens[i])
    seq = fasta_file.aminoacid_seq_str(i)
    pos = np.random.choice(np.arange(fasta_file.seq_lens[i]-target_length+1), size=1)[0]
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
        if pos+target_length < fasta_file.seq_lens[i]:
            frag_msa[ref_i, membership_targets[pos+target_length]:] = gap_symbol

frag_msa = frag_msa[:, ~np.all(frag_msa == gap_symbol, axis=0)]
        
alphabet = fasta.alphabet[:-1] + ["-"]
for i, seq_id in enumerate(ref_fasta.seq_ids):
    aligned_seq = "" 
    for j in frag_msa[i]:
        aligned_seq += alphabet[j]
    out_ref.write(">"+seq_id+"\n")
    out_ref.write(aligned_seq+"\n")
    
        
out.close()
out_ref.close()