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
        if [ ! -f "alignments/$filename" ]; then
            { time python3 /home/bioinf.lan/fbecker/bin_aligners/MAGUS/magus.py -d ./work_${filename%.fasta} --recurse \
false -t clustal -i $f -o "alignments/$filename" ; } 2> times/${filename%.fasta}.time.txt
        fi
    done
}

run "${HOMFAM}"                                                                                                        
run "${BALIFAM100}"                                                                                                    
run "${BALIFAM1000}"
run "${BALIFAM10000}"                                                                                                  
run "${BALIFRAG}"                                                                                                      













