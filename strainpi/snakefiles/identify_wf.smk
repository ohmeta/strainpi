#!/usr/bin/env snakemake

import sys
from pprint import pprint
import pandas as pd
from snakemake.utils import min_version

min_version("7.0")
shell.executable("bash")

sys.path.insert(0, "/home/jiezhu/toolkit/strainpi")
import strainpi

STRAINPI_DIR = strainpi.__path__[0]
WRAPPER_DIR = os.path.join(STRAINPI_DIR, "wrappers")
DATA_DIR = os.path.join(STRAINPI_DIR, "data")

pprint(STRAINPI_DIR)

TRIMMING_DO = any([
    config["params"]["trimming"]["sickle"]["do"],
    config["params"]["trimming"]["fastp"]["do"],
    config["params"]["trimming"]["trimmomatic"]["do"]
])


RMHOST_DO = any([
    config["params"]["rmhost"]["bwa"]["do"],
    config["params"]["rmhost"]["bowtie2"]["do"],
    config["params"]["rmhost"]["minimap2"]["do"],
    config["params"]["rmhost"]["kraken2"]["do"],
    config["params"]["rmhost"]["kneaddata"]["do"]
])


IDENTIFIERS = []

if config["params"]["identify"]["strainphlan"]["do"]:
    IDENTIFIERS += ["strainphlan"]
if config["params"]["identify"]["instrain"]["do"]:
    IDENTIFIERS += ["strainphlan"]


SAMPLES, DATA_TYPE = strainpi.parse_samples(config["params"]["samples"])
SAMPLES_ID_LIST = SAMPLES.index.get_level_values("sample_id").unique()


include: "../rules/raw.smk"
include: "../rules/trimming.smk"
include: "../rules/rmhost.smk"
include: "../rules/qcreport.smk"


rule all:
    input:
        rules.raw_all.input,
        rules.trimming_all.input,
        rules.rmhost_all.input,
        rules.qcreport_all.input
