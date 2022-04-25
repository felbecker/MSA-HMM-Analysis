#!/bin/bash
mkdir homfam
cd homfam
wget http://www.clustal.org/omega/homfam-20110613-25.tar.gz
tar -xvf homfam-20110613-25.tar.gz
rm homfam-20110613-25.tar.gz
mkdir refs
mkdir train
mv *_test-only.vie train
mv *_ref.vie refs
for file in refs/*.vie
do
    mv $file ${file%_ref.vie}.ref
done
for file in train/*.vie
do
    fasta_file=${file%_test-only.vie}.fasta
    mv $file $fasta_file
    chmod +w $fasta_file
    filename=$(basename "$fasta_file")
    python3 ../src/RemoveGapsAndMerge.py $fasta_file refs/${filename%.fasta}.ref
    chmod -w $fasta_file
done
