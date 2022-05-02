#!/bin/bash

HOMFAM="../../data/homfam/refs/*.ref"
BALIFAM100="../../data/balifam100/refs/*.ref"
BALIFAM1000="../../data/balifam1000/refs/*.ref"
BALIFAM10000="../../data/balifam10000/refs/*.ref"
LARGE="../../data/large/refs/*.ref"

cd $1
rm *.out

eval () {
    for f in ${1}
    do
        filename=$(basename "$f")
        output_aln="alignments/${filename%.ref}.fasta"
        projection="alignments/${filename%.ref}.projection.fasta"
        id_list=$(sed -n '/^>/p' "$f" | sed 's/^.//')
        if [ ! -f "$projection" ]
        then
            t_coffee -other_pg seq_reformat -in "$output_aln" -action +extract_seq_list "${id_list[@]}" +rm_gap > "$projection"
        fi
        sp=$(t_coffee -other_pg aln_compare -al1 "$f" -al2 "$projection" -compare_mode sp \
                    | grep -v "seq1" | grep -v '*' | awk '{ print $4}')
        modeler=$(t_coffee -other_pg aln_compare -al1 "$projection" -al2 "$f" -compare_mode sp \
                                          | grep -v "seq1" | grep -v '*' | awk '{ print $4}')
        tc=$(t_coffee -other_pg aln_compare -al1 "$f" -al2 "$projection" -compare_mode tc \
                    | grep -v "seq1" | grep -v '*' | awk '{ print $4}')
        col=$(t_coffee -other_pg aln_compare -al1 "$f" -al2 "$projection" -compare_mode column \
                                          | grep -v "seq1" | grep -v '*' | awk '{ print $4}')
        time_file="times/${filename%.ref}.time.txt"
        time="$(grep real $time_file | sed -e "s/^real\t//")"
        echo "${filename%.ref} $sp $modeler $tc $col $time" >> "${3}.${2}.out"
    done
}

eval "$HOMFAM" "homfam" "$1"
eval "$BALIFAM100" "balifam100" "$1"
eval "$BALIFAM1000" "balifam1000" "$1"
eval "$BALIFAM10000" "balifam10000" "$1"
eval "$LARGE" "large" "$1"
