#!/bin/bash
git clone https://github.com/rcedgar/balifam
for x in 100 1000 10000
do
    mkdir balifam$x
    mkdir balifam$x/train
    mkdir balifam$x/refs
    cp balifam/balifam${x}/in/* balifam$x/train
    cp balifam/balifam${x}/ref/* balifam$x/refs
    for file in balifam$x/train/*
    do
	mv $file $file.fasta
	chmod -w $file.fasta
    done
    for file in balifam$x/refs/*
    do
	mv $file $file.ref
	chmod -w $file.ref
    done
done
#make fragmentary version of balifam10000
mkdir balifrag
mkdir balifrag/train
mkdir balifrag/refs
for file in balifam10000/train/*
do
    filename=$(basename "$file")
    target_file=balifrag/train/${filename%.10000.fasta}.frag.fasta
    target_ref_file=balifrag/refs/${filename%.10000.fasta}.frag.ref
    python3 ../src/MakeFragmentary.py $file balifam10000/refs/${filename%.fasta}.ref $target_file $target_ref_file
    chmod -w $target_file
    chmod -w $target_ref_file
done
rm -rf balifam
