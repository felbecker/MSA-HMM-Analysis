#!/bin/bash

HOMFAM="../../data/homfam/train/*.fasta"
BALIFAM100="../../data/balifam100/train/*.fasta"
BALIFAM1000="../../data/balifam1000/train/*.fasta"
BALIFAM10000="../../data/balifam10000/train/*.fasta"
LARGE="../../data/large/train/*.fasta"

run () {
    for f in $1
    do
	filename=$(basename "$f")
	#-t clustal failed for ldh, idh and rvp, used -fasttree instead
	if [ ! -f "alignments/$filename" ]; then
	    if [ $filename == "ldh.fasta" ] || [ $filename == "idh.fasta" ] || [ $filename == "rvp.fasta" ]; then
		{ time python3 /home/felix/MAGUS/magus.py -d ./work_${filename%.fasta} -t fasttree -i $f -o "alignments/$filename" ; } 2> times/${filename%.fasta}.time.txt
	    else
		{ time python3 /home/felix/MAGUS/magus.py -d ./work_${filename%.fasta} -t clustal -i $f -o "alignments/$filename" ; } 2> times/${filename%.fasta}.time.txt
	    fi
	fi
    done
}

run "${HOMFAM}"
run "${BALIFAM100}"
run "${BALIFAM1000}"
run "${BALIFAM10000}"
run "${LARGE}"















