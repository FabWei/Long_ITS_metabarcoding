#!/bin/bash

# Dereplicate the data
set -euo pipefail
DATADIR="${snakemake_params[datadir]}"

ID="${snakemake_params[id]}"
MINSL="${snakemake_params[minsl]}"

#source /home/ge53xen/miniconda3/bin/activate
#conda activate seqkit

for file in "$DATADIR/01_Trimming/barcode"*
do
       seqkit fq2fa "${file}/output_reads.fastq" -o "${file}/output.fasta"
done


mkdir -p "$DATADIR/03_pre-Clustering/"
mkdir "$DATADIR/03_pre-Clustering/01_Dereplicate/"
mkdir "$DATADIR/03_pre-Clustering/02_Clustering"

#conda activate vsearch

for file in "$DATADIR/01_Trimming/barcode"*
do
       folder=$(basename "${file}")
       vsearch  --derep_fulllength "${file}/output.fasta" \
        --sizeout --output "$DATADIR/03_pre-Clustering/01_Dereplicate/${folder}_derep.fasta" \
       --relabel ${folder}.
done

# pre-Clustering
for file in "$DATADIR/03_pre-Clustering/01_Dereplicate/barcode"*
do
       folder=$(basename "${file}" _derep.fasta)
       mkdir -p "$DATADIR/03_pre-Clustering/02_Clustering/${folder}"
       vsearch --cluster_size "${file}" --id "$ID" \
         --consout "$DATADIR/03_pre-Clustering/02_Clustering/${folder}/consensus.fasta" \
         --sizeout --sizein --minsl "$MINSL" --clusterout_id \
         --centroids "$DATADIR/03_pre-Clustering/02_Clustering/${folder}/centroids.fasta"
done