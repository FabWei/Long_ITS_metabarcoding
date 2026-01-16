# Full ITS data processing for Nanopore sequences 🧬

This pipeline compiles various tools for processing data from Oxford Nanopore Technologies (ONT) for fungal metabarcodign studies using the full ITS. It provides a modular solution suitable for trimming and filtering data, removing chimeras and host contamination, extracting the ITS fragment, and allowing taxonomic classification. Although it was created to process data from fungal ITS with a high content of host reads, it could be adjusted to work with other eukaryotes or user's necessities. 

![](/Long_ITS_metabarcoding/Figures/Workflow.jpeg)


## Requirements and dependencies

This pipeline was implemented in snakemake and requires conda to create the different environments. Here are listed the version of the tools that we tested; however, new versions might work and should be modified in the `envs` files.

### Dependencies

Please install these dependencies before running the pipeline
- [Conda](https://docs.conda.io/projects/conda/en/stable/user-guide/install/windows.html) (v25.9.1)
- [Snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) (v9.13.7)
- [osfclient](https://pypi.org/project/osfclient/) (v0.0.5): `pip install osfclient`


### Environments

The environments listed below will be created automatically. Please consider that it can take some minutes for creating and installing everything when running for first time.
- [Cutadapt](https://cutadapt.readthedocs.io/en/stable/) (v5.2)
- [Nanoplot](https://github.com/wdecoster/NanoPlot) (v1.46.2)
- [SeqKit](https://bioinf.shenwei.me/seqkit/) (v2.12.0)
- [vsearch](https://github.com/torognes/vsearch) (v2.30.1)
- [minimap2](https://github.com/lh3/minimap2) (v2.30-r1287)
- [Samtools](https://github.com/samtools/samtools) (v1.23)
- [ITSx](https://microbiology.se/software/itsx/) (v1.1.3)
- [Emu](https://github.com/treangenlab/emu)  (v3.5.5)

### Databases

We tested the pipeline with the Unite database as described below. A [DB_folder](/DB_folder/) is available to upload your databases and if Emu is used as classifier, the databases will be automatically downloaded. However, different version or databases could be also implemented. Please refer to the [Taxonomic classification](#8-taxonomic-classification) section for more information.

- [Unite for vsearch/sintax](https://unite.ut.ee/repository.php) (v10)
- [Unite for Emu](https://osf.io/56uf7/overview) (v9)

## Data processing

### Before starting
- Test the correct installation of the dependencies and environements using the [Example](/Example/) data. Indicate the path of the [Example](/Example/) folder in the **datadir** parameter of the [config.yaml](/config.yaml) file.
- Do not forget to run snakemake using the `--use-conda` flag. Otherwise, the environments will not be created.
- Be sure that you have enough storage space in the folder provided with your data. All the outputs will be created in the same path. 
- Modify the parameters in the [config.yaml](/config.yaml) file, when needed.

### 1. Input data
This pipeline was designed to use demultiplexed data as an input. We suggest to use [Dorado](https://github.com/nanoporetech/dorado) and [Guppy](https://nanoporetech.com/document/Guppy-protocol#guppy-software-overview) to perform the basecalling and demultiplexing process. In case of questions, please use this [guide](https://github.com/Claudia-Barrera/Nanopore_16S) as a reference. Once demultiplexed your sequenced should be organized in individual folders per barcode named as `barcode*` and compiled in a main folder. Please set the path to the main folder in the [config.yaml](/config.yaml) file using the **datadir** parameter.

### 2. Trimming
In this step, the primers and adapters will be trimmed and the low quality reads will be removed. Please indicate in the [config.yaml](/config.yaml) file the parameters you want to use. You can use a first quality control as reference to define the filtering parameters as suggested [here](https://github.com/Claudia-Barrera/Nanopore_16S) or use tentative values and compare the results after the quality control in the next step.
- **forward:** *primer sequences*. The adapter and the sequence preceding the `forward` primer will be trimmed. 
- **reverse:** *primer sequence*. The adapter and the sequence following the `reverse` primer will be trimmed. 
- **q_score:** *real*. Minimmun q-score to keep a read. Default 10.
- **min_length:** *real*. Minimmun length to keep a read. Default 580.
- **max_length:** *real*. Maximmun length to keep a read. Default 1050.

A new `01_Trimming` folder will be created with the clean reads.

### 3. Quality control
The quality of the filtered and trimmed sequences will be evalauted and compare it with the files before cleaning. This step will be performed automatically after trimming. You will get a new `02_QualityControl_2` folder with a report of the quality of the samples before (`barcode*_beforeNanoPlot-report.html`) and after trimming (`barcode*_afterNanoPlot-report.html`). Additionally, a `Stats_summary.txt`file will be created summarizing some of the metricts evalauted during the quality control.

|barcode01 | Before | After|
| --- | --- | --- |
|Mean_read_length: |	1524.3 |	1524.6 |
|Mean_read_quality: |	12.3 |	13.1 |
|Median_read_length: |	1616	| 1520 |
|Median_read_quality: |	15.7	| 16.5 |
|Number_of_reads:	| 40553 |	21305 |
|Read_length_N50:	| 1622 |	1521 |
|STDEV_read_length:	| 499.2 |	65.1 |
|**barcode02**		|
| ... | ... | ... |

### 4. Pre-clustering
To reduce the processing power, data will be dereplicated and pre-clustered. Adjust the clustering parameters in the [config.yaml](/config.yaml) file if needed.
- **id:** *real*. Value ranging from 0.0 to 1.0 to define the pairwise identity. Default 0.97.
- **minsl:** *real*. Reject if the shorter/longer sequence length ratio is lower than real. Default 0.9.
The output from this step will be saved in a new `03_pre-Clustering` folder.

### 5. Chimera detection
Chimeras will be detected and removed using `--uchime_denovo`. At the end of this step a new `04_Chimeras` folder will be created with the sequences without chimeras (`barcode*.fasta`) and the detected chimeras (`barcode*.chimera.fasta`). Additionally, a `Number.of.reads.txt` with the number of reads retained after chimera removal will be created.

### 6. Host decontamination
In case of high levels of host sequences are expected and the reference genome of the host is known, please indicate the path to the `.fasta` file in the **refseq** parameter of the [config.yaml](/config.yaml) file. Otherwise, let the parameter empty (""). The pipeline will automatically continue with the ITS extraction step.

### 7. ITS extraction
The ITS regions from the sequences will be extracted according to the next parameters:
- **cpu:** *positive integer*. Number of CPU threads to use. This is the step that requires more processing power and time. Default 36.
- **e-val:** *real*. Domain E-value cutoff a sequence must obtain in the HMMERbased step to be included in the output. Smaller numbers will be more restricted and require more time consumption. Default 1e-1.
- **regions:** *string*. A comma separated list of regions to output separate FASTA files for. Default "ITS1,5.8S,ITS2,LSU".

At the end of this step you will get a `05_ITSx` folder with separeted files for each ITS region defined. Additionally, a `Number.of.reads.txt` with the number of reads retained after host decontamination (if included) and ITS extraction will be created.

### 8. Taxonomic classification
The taxonomic classification can be performed using vsearch or Emu. Please set the classifier of your choise in the **classifier** parameter of the [config.yaml](/config.yaml) file. Valid options: "vsearch" or "emu". 

A [DB_folder](/DB_folder/) is available to deposit the databases. Please consider the next specifications for each classifier: 

#### vsearch
Due to the user authentication step required for Unite to download databases, no remote process is supported yet. Please download the "Fungi" and "All eukaryotes" databases directly from UNITE(https://unite.ut.ee/repository.php), under the section "UCHIME/USEARCH/UTAX/SINTAX reference datasets". Then, select the version of your choice and download the `.fasta.gz` file from the PlutoF platform. An authentication windown will promt. Fill out the information and accept the terms and conditions. Once donwloaded, move the databases to the [DB_folder](/DB_folder/) and extract the files using `gunzip DB_file.fasta.gz`. Finally, modify the name of the file in the **unite_vserach** section of the  [config.yaml](/config.yaml) file. An url with the database version used for testing is provided in the **unite_vsearch** section and can be used to download the v10.0. However,no modifcations are required there.

vsearch requires a database in `.fasta` format. Below are suggested some additianal databases that were tested and can be used. However, customized database are also possible, if they suits the format.
- [**Eukaryome**](https://eukaryome.org/sintax/): full ITS operon (SSU-ITS-LSU) database for eukaryotes.
- [**PR2**](https://app.pr2-database.org/pr2-database/): 18S database for protist.

Additionally, when using vsearch adjust the next parameters in the **vsearch_class** section of the [config.yaml](/config.yaml) file, if needed:
- **id:** *real*. Value ranging from 0.0 to 1.0 to define the pairwise identity. Default 0.97
- **minsl:** *real*. Reject if the shorter/longer sequence length ratio is lower than real. Default 0.9
- **minsize:** *positive integer*. Specify the minimum abundance of sequences. Default 2 (singletons will be removed).
- **threads:** *positive integer*. Number of CPU threads to use. Default 20.

#### Emu
For Emu, a prebuilt database for fungi and eukaryotes are downloaded automatically. In case a different database is required, this should be adjusted accordingly. Please refer to the [Emu manual](https://github.com/treangenlab/emu) for more information and change the name of the folders in the **unite_emu** section of the [config.yaml](/config.yaml) file. Additionally, modify the number of threads in the **emu_class** section of the [config.yaml](/config.yaml) file, if needed. 

## Final output

At the end of the classification step the outputs will be stored in the `07_Classification` folder. A classification for fungi and eukaryote will be created. 

For Emu, you will get a `rel-abundance.tsv` file with the relative abundance of each taxon, a `read-assigment-distribution.tsv` file with the distribution of the reads for each barcode. Additionally, an `abundance_euk/fungi.tsv` file with the combined results from all barcodes will be generated. 

For vsearch, an additional `06_Clustering` folder will be created containing the abundance results in the `otutab.txt`file and the representative sequence per OTU in the `representative_seq.fasta` file. A `taxonomy_euk/fungi.txt` file will be available in the `07_Classification` folder. 



