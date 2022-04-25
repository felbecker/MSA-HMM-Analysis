#!/bin/bash

HOMFAM="../../data/homfam/train/*.fasta"
BALIFAM100="../../data/balifam100/train/*.fasta"
BALIFAM1000="../../data/balifam1000/train/*.fasta"
BALIFAM10000="../../data/balifam10000/train/*.fasta"

mkdir -p alignments
mkdir -p times

run () {
    mkdir tmp_files
    for f in $1
    do
	filename=$(basename "$f")
	cp $f tmp_tiles/$filename
	perl replace_U.pl tmp_tiles/$filename
	#if using a mafft installation at the default place, drop the -m option
	{ time mafft-sparsecore.rb -i tmp_tiles/$filename -m/home/felix/bin > alignments/$filename ; } 2> times/${filename%.fasta}.time.txt
    done
    rm -r tmp_files
}

run "${HOMFAM}"
run "${BALIFAM100}"
run "${BALIFAM1000}"
run "${BALIFAM10000}"














