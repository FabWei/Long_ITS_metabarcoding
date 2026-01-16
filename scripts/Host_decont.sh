#!/bin/bash

# Remove host amplicons
set -euo pipefail
DATADIR="${snakemake_params[datadir]}"
Refseq="${snakemake_input[refseq]}"

#source /home/ge53xen/miniconda3/bin/activate
#conda activate minimap2


mkdir -p "$DATADIR/04.b_Host_decontamination"

for file in "$DATADIR/04_Chimeras/barcode"*
do
        folder=$(basename "${file}")
        mkdir -p "$DATADIR/04.b_Host_decontamination/${folder}"
        minimap2 -ax map-ont --sam-hit-only $Refseq "${file}/${folder}.fasta" > \
            "$DATADIR/04.b_Host_decontamination/${folder}/${folder}.map.sam"
done

#conda activate samtools

for file in "$DATADIR/04.b_Host_decontamination/barcode"*
do
    folder=$(basename "${file}")
    samtools fasta  "${file}/${folder}.map.sam" > \
            "${file}/${folder}.fasta"
done