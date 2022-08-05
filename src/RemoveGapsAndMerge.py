import sys
from itertools import groupby

train_filepath = sys.argv[1]
ref_filepath = sys.argv[2]


ref_file = open(ref_filepath, "r")
train_file = open(train_filepath, "r+")

def make_dict(file):
    fasta_dict = {}
    groups = (x[1] for x in groupby(file, lambda line: line[0] == ">"))
    for x in groups:
        seq_id = x.__next__()
        seqs = list(groups.__next__())
        fasta_dict[seq_id] = seqs
    return fasta_dict

ref_dict = make_dict(ref_file)
train_dict = make_dict(train_file)

for seq_id, seqs in ref_dict.items():
    if seq_id not in train_dict:
        train_file.write(seq_id)
        seq = ""
        for s in seqs:
            seq += s.strip().replace("-", "").replace(".", "")
        train_file.write(seq+"\n")


ref_file.close()
train_file.close()
