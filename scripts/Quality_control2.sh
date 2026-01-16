#!/bin/bash

# Check the quality of the reads before and after trimming
set -euo pipefail
DATADIR="${snakemake_params[datadir]}"

#source /home/ge53xen/miniconda3/bin/activate
#conda activate nanoplot

mkdir -p "$DATADIR/02_QualityControl_2"

# Check the quality of the separated barcodes before cleaning
for file in "$DATADIR/00_Raw_data/barcode"*
do
        folder=$(basename "${file}")
        mkdir "$DATADIR/02_QualityControl_2/${folder}"
        NanoPlot --fastq "${file}/complete.fastq" -o "$DATADIR/02_QualityControl_2/${folder}" -p ${folder}_before
done

# Check the quality of the separated barcodes after cleaning
for file in "$DATADIR/01_Trimming/barcode"*
do
       folder=$(basename "${file}")
       NanoPlot --fastq "${file}/output_reads.fastq" -o "$DATADIR/02_QualityControl_2/${folder}" -p ${folder}_after
done

# Create a summary table using the Stats results
for file in "$DATADIR/02_QualityControl_2/barcode"*
do
        folder=$(basename "${file}")
        sed -n 2,8p "${file}/${folder}_beforeNanoStats.txt" | sed 's/ /_/;s/ /_/' > "${file}/${folder}_Stats_before.txt"
        sed -n 2,8p "${file}/${folder}_afterNanoStats.txt" | sed 's/ /_/;s/ /_/' > "${file}/${folder}_Stats_after.txt"
        join "${file}/${folder}_Stats_before.txt" "${file}/${folder}_Stats_after.txt" > "${file}/${folder}_join.txt"
        echo -e ${folder} | cat - "${file}/${folder}_join.txt" > "${file}/${folder}_summary.txt"
done

cat "$DATADIR"/02_QualityControl_2/barcode*/barcode*_summary.txt > "$DATADIR/02_QualityControl_2/Stats_summary.txt"
sed -i -e '1iBarcode Before After\' "$DATADIR/02_QualityControl_2/Stats_summary.txt"