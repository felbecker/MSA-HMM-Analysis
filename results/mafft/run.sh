#!/bin/bash

HOMFAM="../../data/homfam/train/*.fasta"
BALIFAM100="../../data/balifam100/train/*.fasta"
BALIFAM1000="../../data/balifam1000/train/*.fasta"
BALIFAM10000="../../data/balifam10000/train/*.fasta"
BALIFRAG="../../data/balifrag/train/*.fasta"

mkdir -p alignments
mkdir -p times

MAFFT_PATH=""

run () {
    mkdir tmp_files
    for f in $1
    do
	filename=$(basename "$f")
	cp $f tmp_files/$filename
	perl replace_U.pl tmp_files/$filename
	#if using a mafft installation at the default place, drop the -m option
	{ time ${MAFFT_PATH}mafft-sparsecore.rb -i tmp_files/$filename -m ${MAFFT_PATH}/mafft > alignments/$filename ; } 2> times/${filename%.fasta}.time.txt
    done
    rm -r tmp_files
}

run "${HOMFAM}"
run "${BALIFAM100}"
run "${BALIFAM1000}"
run "${BALIFAM10000}"
run "${BALIFRAG}"













