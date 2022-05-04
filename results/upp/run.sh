#!/bin/bash

HOMFAM="../../data/homfam/train/*.fasta"
BALIFAM100="../../data/balifam100/train/*.fasta"
BALIFAM1000="../../data/balifam1000/train/*.fasta"
BALIFAM10000="../../data/balifam10000/train/*.fasta"
BALIFRAG="../../data/balifrag/train/*.fasta"

mkdir -p alignments
mkdir -p times

run () {
    for f in $1
    do
        filename=$(basename "$f")
        mkdir tmp_${filename%.fasta}
        { time python /home/bioinf.lan/fbecker/bin_aligners/sepp/run_upp.py -M -1 -m amino -s $f -d "tmp_${filename%.fasta}" -o "$\
{filename%.fasta}" ; } 2> times/${filename%.fasta}.time.txt
        #upp refuses to align if a file with matching prefix exists in the target dir
        #i.e. if it runs for "blmb" first, it refuses to run on "blm" thereafter
        #we avoid this by using a tmp dir
        mv tmp_${filename%.fasta}/* alignments/
        mv alignments/${filename%.fasta}_alignment.fasta alignments/$filename
        rm -r tmp_${filename%.fasta}
    done
}

run "${HOMFAM}"
run "${BALIFAM100}"
run "${BALIFAM1000}"
run "${BALIFAM10000}"
run "${BALIFRAG}"
