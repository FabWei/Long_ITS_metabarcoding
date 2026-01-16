#!/bin/bash

# Remove chimeras de-novo
set -euo pipefail
DATADIR="${snakemake_params[datadir]}"

#source /home/ge53xen/miniconda3/bin/activate
#conda activate vsearch

mkdir -p "$DATADIR/04_Chimeras"

for file in "$DATADIR/03_pre-Clustering/02_Clustering/barcode"*
do
       folder=$(basename "${file}")
       mkdir -p "$DATADIR/04_Chimeras/${folder}"
       vsearch --uchime_denovo "${file}/centroids.fasta" \
        --nonchimeras "$DATADIR/04_Chimeras/${folder}/${folder}.fasta" \
        --chimeras "$DATADIR/04_Chimeras/${folder}/${folder}.chimera.fasta"
done


for file in "$DATADIR/04_Chimeras/barcode"*
do
       folder=$(basename "${file}")
       echo -e "${folder}\t" "$(grep ">" "${file}/${folder}.fasta" | wc -l)"
done >> "$DATADIR/04_Chimeras/Number.of.reads.txt"