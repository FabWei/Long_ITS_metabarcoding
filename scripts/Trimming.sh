#!/bin/bash

# Trimm the barcodes and filter the bad quality sequences
set -euo pipefail
DATADIR="${snakemake_params[datadir]}"

FORWARD="${snakemake_params[Pforward]}"
REVERSE="${snakemake_params[Preverse]}"
Q_SCORE="${snakemake_params[q_score]}"
MIN_LEN="${snakemake_params[min_length]}"
MAX_LEN="${snakemake_params[max_length]}"


#source /home/ge53xen/miniconda3/bin/activate
#conda activate cutadapt

mkdir -p "$DATADIR/01_Trimming"

for file in "$DATADIR/00_Raw_data/barcode"*; do
    cat "${file}"/*.fastq > "${file}/complete.fastq"
    folder=$(basename "${file}")
    mkdir -p "$DATADIR/01_Trimming/${folder}"
    cutadapt -g "$FORWARD" \
             -a "$REVERSE" \
             -q "$Q_SCORE" \
             --minimum-length "$MIN_LEN" \
             --maximum-length "$MAX_LEN" \
             "${file}/complete.fastq" \
             -o "$DATADIR/01_Trimming/${folder}/output_reads.fastq"
done

mkdir -p "$DATADIR/status"
touch "$DATADIR/status/trimming.done"
