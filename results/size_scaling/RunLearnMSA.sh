#!/bin/bash                                                                                                                                                                                                                                           
#SBATCH --output=./learnMSA.%A_%a.log
#SBATCH -J learnMSA                                                                                                                                                                                                                                       
#SBATCH --time=3-00:00:00                                                                                                                                                                                                                             
#SBATCH -n 16
#SBATCH --partition=pinky
#SBATCH --mem=100000                                                                                                                                                                                                                                  
#SBATCH --array=0-810


FILES=(data/subset_fasta/*.fasta)
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}


FILENAME=$(basename "$FILE")
echo ${FILENAME}

if [ ! -f "data/subset_alignments/$FILENAME" ]
then
learnMSA -i $FILE -o "data/subset_alignments/$FILENAME" -n 1
fi

