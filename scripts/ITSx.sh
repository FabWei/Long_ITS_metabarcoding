#!/bin/bash

# ITS extraction
set -euo pipefail
DATADIR="${snakemake_params[datadir]}"
INPUT="${snakemake_input[files]}"

CPU="${snakemake_params[cpu]}"
E_VAL="${snakemake_params[e_val]}"
REGIONS="${snakemake_params[regions]}"

#source /home/ge53xen/miniconda3/bin/activate
#conda activate itsx
mkdir -p "$DATADIR/05_ITSx"

for file in "$INPUT/barcode"*
do
       folder=$(basename "${file}")
       mkdir -p "$DATADIR/05_ITSx/${folder}"
       ITSx -i "${file}/${folder}.fasta" -o "$DATADIR/05_ITSx/${folder}/${folder}" --cpu "$CPU" \
                -E "$E_VAL" --save_regions "$REGIONS"
done

for file in "$DATADIR/05_ITSx/barcode"*
do
    folder=$(basename "${file}")
    echo -e "${folder}\t" "$(grep ">" "${file}/${folder}.full.fasta" | wc -l)"    
done >>  "$DATADIR/05_ITSx/Number.of.reads.txt"
