#!/bin/bash
#SBATCH --account=naiss2024-22-540
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --job-name=sra_download
#SBATCH --error=sra_download.err
#SBATCH --output=sra_download.out
#SBATCH --mail-type=ALL
#SBATCH --mail-user=guryleva.mv@gmail.com

cat /proj/applied_bioinformatics/users/x_mgury/MedBioinfo/analyses/x_mgury_run_accessions.txt | srun --cpus-per-task=1 --time=00:30:00 singularity exec /proj/applied_bioinformatics/common_data/meta.sif xargs -n 1 fastq-dump --gzip --readids --split-3 --disable-multithreading --outdir ./data/sra_fastq -A 

wait
