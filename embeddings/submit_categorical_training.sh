#!/bin/bash
#SBATCH --job-name=bilin_pfam      # Job name
#SBATCH --nodes=1                    # Run all processes on a single node
#SBATCH --ntasks=1                   # Run a single task
#SBATCH --cpus-per-task=32            # Number of CPU cores per task
#SBATCH --mem=2000gb                    # Job memory request
#SBATCH --time=72:00:00              # Time limit hrs:min:sec
#SBATCH --output=slurm_outputs/bilin_pfam_%j.log     # Standard output and error log
#SBATCH --partition=pinky

conda init bash
conda activate tensorflow

jupyter nbconvert --execute --to notebook FitEmbeddingCategorical.ipynb