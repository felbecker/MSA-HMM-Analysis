#!/bin/bash

HOMFAM="../../data/large/train/*.fasta"

mkdir -p alignments
mkdir -p times

run () {
    mkdir tmp_files_large
    for f in $1
    do
	filename=$(basename "$f")
	cp $f tmp_files_large/$filename
	perl replace_U.pl tmp_files_large/$filename
	{ time mafft --parttree tmp_files_large/$filename > alignments/$filename ; } 2> times/${filename%.fasta}.time.txt
    done
    rm -r tmp_files_large
}

run "${LARGE}"













