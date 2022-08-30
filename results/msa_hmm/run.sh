#!/bin/bash

HOMFAM="../../data/homfam/train/*.fasta"
BALIFAM100="../../data/balifam100/train/*.fasta"
BALIFAM1000="../../data/balifam1000/train/*.fasta"
BALIFAM10000="../../data/balifam10000/train/*.fasta"
BALIFRAG="../../data/balifrag/train/*.fasta"
LARGE="../../data/large/train/*.fasta"

OUT_DIR="./"

mkdir -p ${OUT_DIR}alignments
mkdir -p ${OUT_DIR}logs
mkdir -p ${OUT_DIR}times

run () {
    for f in $1
    do
	filename=$(basename "$f")
	if [ ! -f "${OUT_DIR}alignments/$filename" ]; then
            { time learnMSA -i "$f" -o "${OUT_DIR}alignments/$filename" > "${OUT_DIR}logs/${filename%.fasta}.log" ; } 2> "${OUT_DIR}times/${filename%.fasta}.time.txt"
    fi
    done
}

run "${HOMFAM}"
run "${BALIFAM100}"
run "${BALIFAM1000}"
run "${BALIFAM10000}"
run "${BALIFRAG}"
run "${LARGE}"
