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
rm -rf balifam
