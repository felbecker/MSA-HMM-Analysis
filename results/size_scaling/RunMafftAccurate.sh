#!/bin/bash                                                                                                                                                                                                                                           
#SBATCH --output=./mafft.%A_%a.log

#SBATCH -J mafft                                                                                                                                                                                                                                       
#SBATCH --time=3-00:00:00                                                                                                                                                                                                                             
#SBATCH -n 8
#SBATCH --partition=pinky
#SBATCH --mem=200000

#SBATCH --array=0-810
FILES=(data/subset_fasta_no_u/*.fasta)
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}

~/.rbenv/bin/rbenv global 3.0.0

FILENAME=$(basename "$FILE")
echo ${FILENAME}

if [ ! -f "data/subset_alignments_mafft_sparsecore/$FILENAME" ]
then
~/.rbenv/versions/3.0.0/bin/ruby ~/bin/mafft-7.490-with-extensions/core/mafft-sparsecore.rb -m ~/bin/mafft-7.490-with-extensions/core/mafft -i $FILE > data/subset_alignments_mafft_sparsecore/$FILENAME
fi
