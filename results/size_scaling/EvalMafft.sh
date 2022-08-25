#!/bin/bash                                                                                                                                       

#SBATCH --output=./mafft_eval.%A_%a.log
#SBATCH -J mafft_eval                                                                                                                                    

#SBATCH --time=3-00:00:00                                                                                                                         

#SBATCH -n 8
#SBATCH --partition=pinky
#SBATCH --mem=200000                                                                                                                              

#SBATCH --array=0-810


FILES=(data/subset_alignments_mafft/*.fasta)
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}

FILENAME=$(basename "$FILE")
echo ${FILENAME}

export MAX_N_PID_4_TCOFFEE=4194304

IFS='_' read -r FAMILY REST <<< "$FILENAME"
ref_file="../../data/large/refs/${FAMILY}.ref"
projection="data/subset_alignments_proj_mafft/${FILENAME}"
id_list=$(sed -n '/^>/p' "$ref_file" | sed 's/^.//')
if [ ! -f "$projection" ]
then
    t_coffee -other_pg seq_reformat -in "$FILE" -action +extract_seq_list "${id_list[@]}" +rm_gap > "$projection"
fi
sp=$(t_coffee -other_pg aln_compare -al1 "$ref_file" -al2 "$projection" -compare_mode sp \
         | grep -v "seq1" | grep -v '*' | awk '{ print $4}')
modeler=$(t_coffee -other_pg aln_compare -al1 "$projection" -al2 "$ref_file" -compare_mode sp \
         | grep -v "seq1" | grep -v '*' | awk '{ print $4}')
tc=$(t_coffee -other_pg aln_compare -al1 "$ref_file" -al2 "$projection" -compare_mode tc \
         | grep -v "seq1" | grep -v '*' | awk '{ print $4}')
col=$(t_coffee -other_pg aln_compare -al1 "$ref_file" -al2 "$projection" -compare_mode column \
         | grep -v "seq1" | grep -v '*' | awk '{ print $4}')
         
mkdir -p tmp_mafft

echo ${FILENAME%.fasta} $sp $modeler $tc $col >> tmp_mafft/${SLURM_ARRAY_TASK_ID}.out


