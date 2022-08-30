#!/bin/bash
#You may want to visit the Pfam website and manually the data from families you are interested in.
#Full pfam uniprot is downloaded by this script!
#Allow 2TB of free disk space and quite some time.
#Afterwards, most of it can be freed as we select only as small subset of the families.
#This script does no remove anything on its own.
mkdir large
cd large
get_fasta_data() {
    file=$1
    wget http://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/$file.gz
    gunzip $file.gz
    mkdir ${file}_data
    python3 ../src/SplitStockholm.py $file ${file}_data
    cd ../src
    ./Stockholm2Fasta.sh "../large/${file}_data/*.stockholm"
    cd ../large
}
#get_fasta_data "Pfam-A.full" #one might want to replace "unitprot" with "full", reducing the sequence count but also redundancy
get_fasta_data "Pfam-A.full.uniprot"
get_fasta_data "Pfam-A.seed"
mkdir train
mkdir refs
large_ids=("PF00096.29" "PF00400.35" "PF00005.30" "PF00069.28" "PF12796.10" "PF00041.24" "PF00072.27" "PF07679.19" "PF07690.19" "PF13855.9")
for id in ${large_ids[@]};
do
    cp Pfam-A.seed_data/${id}.fasta refs/${id}.ref
    chmod -w  refs/${id}.ref
    touch train/${id}.fasta
    python3 ../../src/RemoveGapsAndMerge.py train/${id}.fasta refs/${id}.ref
    python3 ../../src/RemoveGapsAndMerge.py train/${id}.fasta Pfam-A.full.uniprot_data/${id}.fasta
    echo -en "\n" >> train/${id}.fasta
    chmod -w train/${id}.fasta
done







