#!/bin/bash

# Taxonomic classification using vsearch
set -euo pipefail
DATADIR="${snakemake_params[datadir]}"
# Databases
DB_fungi="${snakemake_input[db_fungi]}"
DB_euk="${snakemake_input[db_euk]}"

ID="${snakemake_params[id]}"
MINSL="${snakemake_params[minsl]}"
MINSIZE="${snakemake_params[minsize]}"
THREADS="${snakemake_params[threads]}"


#source /home/ge53xen/miniconda3/bin/activate
#conda activate vsearch

# 1. Second dereplication ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

mkdir -p "$DATADIR/06_Clustering"

for file in "$DATADIR/05_ITSx/barcode"*
do
       folder=$(basename "${file}" )
       vsearch --derep_fulllength "${file}/${folder}.full.fasta" \
       --sizeout --sizein \
       --output "$DATADIR/06_Clustering/${folder}_derep2.fasta" \
       --relabel OTU_
done

cat "$DATADIR/06_Clustering/barcode"*_derep2.fasta > "$DATADIR/06_Clustering/ITS_derep2.fasta"

for file in "$DATADIR/05_ITSx/barcode"*
do
       folder=$(basename "${file}" )
       vsearch --derep_fulllength "${file}/${folder}.full.fasta" \
       --sizeout --sizein \
       --output "$DATADIR/06_Clustering/${folder}_derep2_bar.fasta" \
       --relabel ${folder}._
done

cat "$DATADIR/06_Clustering/barcode"*_derep2_bar.fasta > "$DATADIR/06_Clustering/ITS_derep2_bar.fasta"


# 2. Clustering 2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

vsearch --cluster_size "$DATADIR/06_Clustering/ITS_derep2.fasta" \
       --id "$ID" --consout "$DATADIR/06_Clustering/consensus.fasta" \
       --sizeout --sizein --minsl "$MINSL" --clusterout_id \
       --centroids "$DATADIR/06_Clustering/centroids.fasta"

#Relabel OTUs and remove singletons
vsearch --fastx_filter "$DATADIR/06_Clustering/centroids.fasta" \
      --sizein --sizeout --fasta_width 0 --minsize "$MINSIZE"\
      --relabel OTU_ --fastaout "$DATADIR/06_Clustering/representative_seq.fasta"


# 3. Alignment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

vsearch --usearch_global "$DATADIR/06_Clustering/ITS_derep2_bar.fasta" \
      --threads "$THREADS" --db "$DATADIR/06_Clustering/representative_seq.fasta" \
      --id "$ID" --sizein --sizeout \
      --otutabout "$DATADIR/06_Clustering/otutab.txt"


# 4. Classification ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

mkdir -p "$DATADIR/07_Classification"
mkdir -p "$DATADIR/07_Classification/vsearch"

# Using fungal DB
echo "▶ Running vsearch classification with fungal database"
vsearch --sintax "$DATADIR/06_Clustering/representative_seq.fasta" \
      --db "$DB_fungi" \
      --tabbedout "$DATADIR/07_Classification/vsearch/taxonomy_fungi.txt"

# Using all Eukaryotes DB
echo "▶ Running vsearch classification with eukaryote database"
vsearch --sintax "$DATADIR/06_Clustering/representative_seq.fasta" \
      --db "$DB_euk" \
      --tabbedout "$DATADIR/07_Classification/vsearch/taxonomy_euk.txt"