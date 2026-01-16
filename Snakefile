import os
SNAKEFILE_DIR = os.path.dirname(os.path.realpath("Pipeline"))
SCRIPTS = os.path.join(SNAKEFILE_DIR, "scripts")
ENVS = os.path.join(SNAKEFILE_DIR, "envs")
DB = os.path.join(SNAKEFILE_DIR, "DB_folder")


# load configuration
# --------------------------------------------------------------------
configfile: "config.yaml"

DATADIR = config["datadir"]
UNITE_VSEARCH = config["unite_vsearch"]
UNITE_EMU = config["unite_emu"]

# load rules
# --------------------------------------------------------------------

COMMON_OUTPUTS = [
    f"{DATADIR}/02_QualityControl_2/Stats_summary.txt",
    f"{DATADIR}/05_ITSx/Number.of.reads.txt",
]


if config["classifier"] == "vsearch":
    FINAL_OUTPUTS = [
        f"{DATADIR}/07_Classification/vsearch/taxonomy_fungi.txt",
        f"{DATADIR}/07_Classification/vsearch/taxonomy_euk.txt",
    ]

elif config["classifier"] == "emu":
    FINAL_OUTPUTS = [
        f"{DATADIR}/07_Classification/emu/abundance_fungi.tsv",
        f"{DATADIR}/07_Classification/emu/abundance_euk.tsv",
    ]
        
    

else:
    raise ValueError(
        f"Unknown classifier '{config['classifier']}'. "
        "Allowed values: vsearch, emu"
    )


rule all:
    input:
       COMMON_OUTPUTS + FINAL_OUTPUTS


rule prepare_folders:
    params:
        datadir=DATADIR
    output:
        directory(f"{DATADIR}/00_Raw_data")
    shell:
        """
        if compgen -G "{params.datadir}/barcode*" > /dev/null; then
            mkdir -p "{params.datadir}/00_Raw_data"
            mv "{params.datadir}"/barcode* "{params.datadir}/00_Raw_data"
        else
            echo "No barcode folders provided"
        fi
        """


rule trimming_data:
    params:
        datadir=DATADIR,
        Pforward=config["trimming"]["forward"],
        Preverse=config["trimming"]["reverse"],
        q_score=config["trimming"]["q_score"],
        min_length=config["trimming"]["min_length"],
        max_length=config["trimming"]["max_length"]
    input:
        f"{DATADIR}/00_Raw_data"
    output:
        directory(f"{DATADIR}/01_Trimming")
    conda:
        f"{ENVS}/cutadapt.yaml"
    script:
        f"{SCRIPTS}/Trimming.sh"



rule quality_Control2:
    params:
        datadir=DATADIR
    input:
        f"{DATADIR}/01_Trimming"
    output:
        f"{DATADIR}/02_QualityControl_2/Stats_summary.txt"
    conda:
        f"{ENVS}/nanoplot.yaml"
    script:
        f"{SCRIPTS}/Quality_Control2.sh"



rule pre_clustering:
    params:
        datadir=DATADIR,
        id=config["preclustering"]["id"],
        minsl=config["preclustering"]["minsl"]
    input:
        f"{DATADIR}/01_Trimming"
    output:
        directory(f"{DATADIR}/03_pre-Clustering")
    conda:
        f"{ENVS}/vsearch.yaml"
    script:
        f"{SCRIPTS}/pre-clustering.sh"



rule chimeras:
    params:
        datadir=DATADIR
    input:
        f"{DATADIR}/03_pre-Clustering"
    output:
        directory(f"{DATADIR}/04_Chimeras"),
        f"{DATADIR}/04_Chimeras/Number.of.reads.txt"
    conda:
        f"{ENVS}/vsearch.yaml"
    script:
        f"{SCRIPTS}/Chimeras.sh"


if config["refseq"]:
    rule host_decontamination:
        params:
            datadir=DATADIR
        input:
            refseq=config["refseq"]
        output:
            directory(f"{DATADIR}/04.b_Host_decontamination")
        conda:
            f"{ENVS}/minimap2.yaml"
        script:
            f"{SCRIPTS}/Host_decont.sh"
    
    
    rule its_extraction:
        params:
            datadir=DATADIR,
            pu=config["itsx"]["cpu"],
            e_val=config["itsx"]["e_val"],
            regions=config["itsx"]["regions"]
        input:
            files=f"{DATADIR}/04.b_Host_decontamination"
        output:
            f"{DATADIR}/05_ITSx/Number.of.reads.txt",
            directory(f"{DATADIR}/05_ITSx")
        conda:
            f"{ENVS}/itsx.yaml"
        script:
            f"{SCRIPTS}/ITSx.sh"

else:
    rule its_extraction:
        params:
            datadir=DATADIR,
            cpu=config["itsx"]["cpu"],
            e_val=config["itsx"]["e_val"],
            regions=config["itsx"]["regions"]
        input:
            files=f"{DATADIR}/04_Chimeras"
        output:
            f"{DATADIR}/05_ITSx/Number.of.reads.txt",
            directory(f"{DATADIR}/05_ITSx")
        conda:
            f"{ENVS}/itsx.yaml"
        script:
            f"{SCRIPTS}/ITSx.sh"
    


if config["classifier"] == "vsearch":
    rule vsearch_classification:
        params:
            datadir=DATADIR,
            id=config["vsearch_class"]["id"],
            minsl=config["vsearch_class"]["minsl"], 
            minsize=config["vsearch_class"]["minsize"], 
            threads=config["vsearch_class"]["threads"] 
        input:
            its_dir=f"{DATADIR}/05_ITSx",
            db_fungi=f"{DB}/{UNITE_VSEARCH['fungi']['file']}",
            db_euk=f"{DB}/{UNITE_VSEARCH['euk']['file']}"
        output:
            f"{DATADIR}/07_Classification/vsearch/taxonomy_fungi.txt",
            f"{DATADIR}/07_Classification/vsearch/taxonomy_euk.txt"
        conda:
            f"{ENVS}/vsearch.yaml"
        script:
            f"{SCRIPTS}/vsearch_classification.sh"

else:
    rule emu_database:
        params:
            database=f"{DB}",
            db1="unite-fungi",
            db2="unite-all"
        output:
            db_emu_fungi=directory(f"{DB}/Emu_DB/{UNITE_EMU['fungi']}"),
            db_emu_euk=directory(f"{DB}/Emu_DB/{UNITE_EMU['euk']}")
        shell:
            """
            mkdir -p {params.database}/Emu_DB
            cd {params.database}/Emu_DB

            # DB fungi
            osf -p 56uf7 fetch osfstorage/emu-prebuilt/{params.db1}.tar
            tar -xvf {params.db1}.tar --one-top-level

            # DB eukaryotes
            osf -p 56uf7 fetch osfstorage/emu-prebuilt/{params.db2}.tar
            tar -xvf {params.db2}.tar --one-top-level
            """

    rule emu_classification:
        params:
            datadir=DATADIR,
            threads=config["emu_class"]["threads"]
        input:
            its_dir=f"{DATADIR}/05_ITSx",
            db_emu_fungi=f"{DB}/Emu_DB/{UNITE_EMU['fungi']}",
            db_emu_euk=f"{DB}/Emu_DB/{UNITE_EMU['euk']}"
        output:
            f"{DATADIR}/07_Classification/emu/abundance_fungi.tsv",
            f"{DATADIR}/07_Classification/emu/abundance_euk.tsv"
        conda:
            f"{ENVS}/emu.yaml"
        script:
            f"{SCRIPTS}/Emu_classification.sh"


#db_emu_fungi=f"{DATABASE}/UNITE_EMU['fungi']",
#db_emu_euk=f"{DATABASE}/UNITE_EMU['euk']"



