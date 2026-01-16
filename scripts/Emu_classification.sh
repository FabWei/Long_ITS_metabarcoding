#!/bin/bash

# Taxonomic classification using Emu
set -euo pipefail
DATADIR="${snakemake_params[datadir]}"
# Databases
DB_emu_fungi="${snakemake_input[db_emu_fungi]}"
DB_emu_euk="${snakemake_input[db_emu_euk]}"

THREADS="${snakemake_params[threads]}"

#source /home/ge53xen/miniconda3/bin/activate
#conda activate emu

mkdir -p "$DATADIR/07_Classification"
mkdir -p "$DATADIR/07_Classification/emu"

# Using fungal DB

echo "▶ Running EMU classification with fungal database"

for file in "$DATADIR/05_ITSx/barcode"*
do
        folder=$(basename "${file}" )
        emu abundance "${file}/${folder}.full.fasta" --threads "$THREADS" --db $DB_emu_fungi \
                --output-dir "$DATADIR/07_Classification/emu/fungi" --output-unclassified \
                --output-basename ${folder} \
                --keep-counts --keep-read-assignments
done

emu combine-outputs "$DATADIR/07_Classification/emu/fungi" "tax_id" --counts 
mv "$DATADIR/07_Classification/emu/fungi/emu-combined-tax_id-counts.tsv" "$DATADIR/07_Classification/emu/fungi/abundance_fungi.tsv" 
mv "$DATADIR/07_Classification/emu/fungi/abundance_fungi.tsv" "$DATADIR/07_Classification/emu"



# Using all Eukaryotes DB

echo "▶ Running EMU classification with eukaryote database"

for file in "$DATADIR/05_ITSx/barcode"*
do
        folder=$(basename "${file}" )
        emu abundance "${file}/${folder}.full.fasta" --threads "$THREADS" --db $DB_emu_euk \
                --output-dir "$DATADIR/07_Classification/emu/euk" --output-unclassified \
                --output-basename ${folder} \
                --keep-counts --keep-read-assignments
done

emu combine-outputs "$DATADIR/07_Classification/emu/euk" "tax_id" --counts > "$DATADIR/07_Classification/emu/abundance_euk.tsv"
mv "$DATADIR/07_Classification/emu/euk/emu-combined-tax_id-counts.tsv" "$DATADIR/07_Classification/emu/euk/abundance_euk.tsv" 
mv "$DATADIR/07_Classification/emu/euk/abundance_euk.tsv" "$DATADIR/07_Classification/emu"


