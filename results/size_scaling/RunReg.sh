#!/bin/bash                                                                                                                                                                                                                                           
#SBATCH --output=./reg.%A_%a.log
#SBATCH -J reg                                                                                                                                                                                                                                       
#SBATCH --time=3-00:00:00                                                                                                                                                                                                                             
#SBATCH -n 8
#SBATCH --partition=pinky
#SBATCH --mem=200000                                                                                                                                                                                                                                  
#SBATCH --array=0-810


FILES=(data/subset_fasta/*.fasta)
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}


FILENAME=$(basename "$FILE")
echo ${FILENAME}

#see https://github.com/cbcrg/tcoffee/issues/27                                                      
export MAX_N_PID_4_TCOFFEE=4194304

if [ ! -f "data/subset_alignments_reg/$FILENAME" ]
then
t_coffee -seq $FILE -reg -nseq 1000 -tree parttree -method mafftfftnsi_msa -thread 8 -outfile data/subset_alignments_reg/$FILENAME -outtree data/trees/${FILENAME%.fasta}.mbed
fi

