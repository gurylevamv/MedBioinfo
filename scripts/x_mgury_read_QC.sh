sqlite3 /proj/applied_bioinformatics/common_data/sample_collab.db

INSERT INTO bioinformaticians(username, firstname, lastname) VALUES("x_mgury", "Mariia", "Guryleva");

SELECT * FROM sample_annot LEFT OUTER JOIN sample2bioinformatician ON sample_annot.patient_code = sample2bioinformatician.patient_code ORDER BY username;

INSERT INTO sample2bioinformatician(username, patient_code) VALUES("x_mgury", "P20");
INSERT INTO sample2bioinformatician(username, patient_code) VALUES("x_mgury", "P24");
INSERT INTO sample2bioinformatician(username, patient_code) VALUES("x_mgury", "P36");
INSERT INTO sample2bioinformatician(username, patient_code) VALUES("x_mgury", "P381");
INSERT INTO sample2bioinformatician(username, patient_code) VALUES("x_mgury", "P82");

#image has already excisted
#apptainer build --fakeroot x_mgury_assignment.sif /proj/applied_bioinformatics/common_data/meta.def

sbatch scripts/sbatch_sra.sh

#manual counting of lines
for file in *.gz; do echo "$file: $(zcat "$file" | grep "@" | wc -l) lines"; done

#stat with seqkit
find . -name "*.gz"| srun --cpus-per-task=4 singularity exec /proj/applied_bioinformatics/common_data/meta.sif xargs -n 1 seqkit stat --threads 4

# can you use a seqkit sub-command to check if the FASTQ files have been de-replicated (duplicate identical reads removed)? yes, rmdup -D
# can we guess/search for adapter sequences with seqkit? yes, seqkit grep -s -i -p "adapter-seq" FASTQ.gz

#fastqc
srun --account=naiss2024-22-540 --cpus-per-task=2 --time=00:30:00 singularity exec /proj/applied_bioinformatics/common_data/meta.sif xargs -I{} -a ./analyses/x_mgury_run_accessions.txt fastqc ./data/sra_fastq/{}_1.fastq.gz ./data/sra_fastq/{}_2.fastq.gz --threads 2 -o ./analyses/fastqc/ -f fastq --noextract

#merge reads
srun --cpus-per-task=2 --time=00:30:00 singularity exec /proj/applied_bioinformatics/common_data/meta.sif xargs -a sra_fastq/x_mgury_run_accessions.txt -I{} flash --threads 2 -d merged_pairs -o {}.flash --compress sra_fastq/{}_1.fastq.gz sra_fastq/{}_2.fastq.gz 2>&1 | tee -a x_mgury_flash2.log
mv x_mgury_flash2.log ../analyses/

#download PhiX genome
mkdir reference_seqs
singularity exec /proj/applied_bioinformatics/common_data/meta.sif efetch -db nuccore -id NC_001422 -format fasta > reference_seqs/PhiX_NC_001422.fna

#head PhiX_NC_001422.fna

mkdir bowtie2_DBs
srun singularity exec /proj/applied_bioinformatics/common_data/meta.sif bowtie2-build -f reference_seqs/PhiX_NC_001422.fna bowtie2_DBs/PhiX_bowtie2_DB

srun --cpus-per-task=8 singularity exec /proj/applied_bioinformatics/common_data/meta.sif bowtie2 -x ./data/bowtie2_DBs/PhiX_bowtie2_DB -U ./data/merged_pairs/ERR*.extendedFrags.fastq.gz -S ./analyses/bowtie/x_mgury_merged2PhiX.sam --threads 8 --no-unal 2>&1 | tee ./analyses/bowtie/x_mgury_bowtie_merged2PhiX.log

#SARS
singularity exec /proj/applied_bioinformatics/common_data/meta.sif efetch -db nuccore -id NC_045512 -format fasta > ./data/reference_seqs/SARS_NC_045512.fna

srun singularity exec /proj/applied_bioinformatics/common_data/meta.sif bowtie2-build -f ./data/reference_seqs/SARS_NC_045512.fna ./data/bowtie2_DBs/SARS_bowtie2_DB 

srun --cpus-per-task=8 singularity exec /proj/applied_bioinformatics/common_data/meta.sif bowtie2 -x ./data/bowtie2_DBs/SARS_bowtie2_DB -U ./data/merged_pairs/ERR*.extendedFrags.fastq.gz -S ./analyses/bowtie/x_mgury_merged2SARS.sam --threads 8 --no-unal 2>&1 | tee ./analyses/bowtie/x_mgury_bowtie_merged2SARS.log

#there are some reads aligned to SARS-CoV 2 (3809 reads)

srun singularity exec /proj/applied_bioinformatics/common_data/meta.sif multiqc --force --title "x_mgury sample sub-set" ./data/merged_pairs/ ./analyses/fastqc/ ./analyses/x_mgury_flash2.log ./analyses/bowtie/

