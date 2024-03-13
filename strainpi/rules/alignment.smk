def alignment_input(wildcards):
    if RMHOST_DO:
        return os.path.join(config["output"]["rmhost"], f"reads/{wildcards.sample}/{wildcards.sample}.json")
    elif TRIMMING_DO:
        return os.path.join(config["output"]["trimming"], f"reads/{wildcards.sample}/{wildcards.sample}.json")
    else:
        return os.path.join(config["output"]["raw"], f"reads/{wildcards.sample}/{wildcards.sample}.json")


BOWTIE2_LARGE_INDEX_SUFFIX = ["1.bt2l", "2.bt2l", "3.bt2l", "4.bt2l", "rev.1.bt2l", "rev.2.bt2l"]


rule alignment_bowtie2:
    input:
        reads = lambda wildcards: alignment_input(wildcards),
        index = expand(
            "{prefix}.{suffix}",
            prefix=config["params"]["alignment"]["bowtie2"]["index_prefix"],
            suffix=BOWTIE2_LARGE_INDEX_SUFFIX)
    output:
        os.path.join(config["output"]["alignment"], "bam/bowtie2/{sample}/{sample}.json")
    log:
        os.path.join(config["output"]["alignment"], "logs/bowtie2/{sample}.log")
    benchmark:
        os.path.join(config["output"]["alignment"], "benchmark/bowtie2/{sample}.txt")
    params:
        pe_bam_dir = os.path.join(config["output"]["alignment"], "bam/bowtie2/{sample}/pe"),
        se_bam_dir = os.path.join(config["output"]["alignment"], "bam/bowtie2/{sample}/se"),
        report_dir = os.path.join(config["output"]["alignment"], "report/bowtie2/{sample}"),
        presets = config["params"]["alignment"]["bowtie2"]["preset"],
        index_prefix = config["params"]["alignment"]["bowtie2"]["index_prefix"]
    priority:
        24
    conda:
        config["envs"]["bowtie2"]
    threads:
        config["params"]["alignment"]["threads"]
    shell:
        '''
        OUTDIR=$(dirname {output})
        OUTPE=$(dirname {params.pe_bam_dir})
        OUTSE=$(dirname {params.se_bam_dir})

        rm -rf $OUTDIR {params.report_dir}
        mkdir -p $OUTDIR {params.report_dir}

        R1=$(jq -r -M '.PE_FORWARD' {input.reads} | sed 's/^null$//g')
        R2=$(jq -r -M '.PE_REVERSE' {input.reads} | sed 's/^null$//g')
        RS=$(jq -r -M '.SE' {input.reads} | sed 's/^null$//g')

        BAMPE=""
        BAMSE=""
        STATSPE=""
        STATSSE=""

        if [ "$R1" != "" ];
        then
            mkdir -p $OUTPE

            BAMPE={params.pe_bam_dir}/sorted.bam
            STATSPE={params.report_dir}/align_stats.PE.txt

            bowtie2 \
            --threads {threads} \
            -x {params.index_prefix} \
            -1 $R1 \
            -2 $R2 \
            {params.presets} \
            2> {log} | \
            tee >(samtools flagstat \
                -@4 - > $STATSPE) | \
            samtools sort \
            -m 3G \
            -@4 \
            -T {params.pe_bam_dir}/temp \
            -O BAM -o $BAM -
        fi

        if [ "$RS" != "" ];
        then
            mkdir -p $OUTSE
 
            BAMSE={params.se_bam_dir}/sorted.bam
            STATSSE={params.report_dir}/align_stats.PE.txt

            bowtie2 \
            {params.presets} \
            --threads {threads} \
            -x {params.index_prefix} \
            -U $RS \
            2> {log} | \
            tee >(samtools flagstat \
                -@4 - > $STATSSE) | \
            samtools sort \
            -m 3G \
            -@4 \
            -T {params.se_bam_dir}/temp \
            -O BAM -o $BAM -
        fi

        echo "{{ \
        \\"BAM_PE\\": \\"$BAMPE\\", \
        \\"BAM_SE\\": \\"$BAMSE\\", \
        \\"PE_ALIGN_STATS\\": \\"$STATSPE\\", \
        \\"SE_ALIGN_STATS\\": \\"$STATSSE\\" }}" | \
        jq . > {output}
        '''


if config["params"]["alignment"]["bowtie2"]["do"]:
    rule alignment_bowtie2_all:
        input:
            expand(os.path.join(
                config["output"]["alignment"], "bam/bowtie2/{sample}/{sample}.json"),
                sample=SAMPLES_ID_LIST)

else:
    rule alignment_bowtie2_all:
        input:



rule alignment_strobealign:
    input:
        reads = lambda wildcards: alignment_input(wildcards),
        index = expand(
            "{prefix}.r{reads_length}.sti",
            prefix=config["params"]["alignment"]["strobealign"]["index_prefix"],
            reads_length=config["params"]["alignment"]["strobealign"]["read_length"])
    output:
        os.path.join(config["output"]["alignment"], "bam/strobealign/{sample}/{sample}.json")
    log:
        os.path.join(config["output"]["alignment"], "logs/strobealign/{sample}.log")
    benchmark:
        os.path.join(config["output"]["alignment"], "benchmark/strobealign/{sample}.txt")
    params:
        pe_bam_dir = os.path.join(config["output"]["alignment"], "bam/strobealign/{sample}/pe"),
        se_bam_dir = os.path.join(config["output"]["alignment"], "bam/strobealign/{sample}/se"),
        report_dir = os.path.join(config["output"]["alignment"], "report/strobealign/{sample}"),
        index_prefix = config["params"]["alignment"]["strobealign"]["index_prefix"],
        read_length = config["params"]["alignment"]["strobealign"]["read_length"]
    priority:
        24
    conda:
        config["envs"]["strobealign"]
    threads:
        config["params"]["alignment"]["threads"]
    shell:
        '''
        OUTDIR=$(dirname {output})
        OUTPE=$(dirname {params.pe_bam_dir})
        OUTSE=$(dirname {params.se_bam_dir})

        rm -rf $OUTDIR {params.report_dir}
        mkdir -p $OUTDIR {params.report_dir}

        R1=$(jq -r -M '.PE_FORWARD' {input.reads} | sed 's/^null$//g')
        R2=$(jq -r -M '.PE_REVERSE' {input.reads} | sed 's/^null$//g')
        RS=$(jq -r -M '.SE' {input.reads} | sed 's/^null$//g')

        BAMPE=""
        BAMSE=""
        STATSPE=""
        STATSSE=""

        if [ "$R1" != "" ];
        then
            mkdir -p $OUTPE

            BAMPE={params.pe_bam_dir}/sorted.bam
            STATSPE={params.report_dir}/align_stats.PE.txt

            strobealign \
            --use-index \
            --threads {threads} \
            -r {params.read_length}
            {params.index_prefix} \
            $R1 \
            $R2 \
            2> {log} | \
            tee >(samtools flagstat \
                -@4 - > $STATSPE) | \
            samtools sort \
            -m 3G \
            -@4 \
            -T {params.pe_bam_dir}/temp \
            -O BAM -o $BAM -
        fi

        if [ "$RS" != "" ];
        then
            mkdir -p $OUTSE
 
            BAMSE={params.se_bam_dir}/sorted.bam
            STATSSE={params.report_dir}/align_stats.PE.txt

            strobealign \
            --use-index \
            --threads {threads} \
            -r {params.read_length} \
            {params.index_prefix} \
            $RS \
            2> {log} | \
            tee >(samtools flagstat \
                -@4 - > $STATSSE) | \
            samtools sort \
            -m 3G \
            -@4 \
            -T {params.se_bam_dir}/temp \
            -O BAM -o $BAM -
        fi

        echo "{{ \
        \\"BAM_PE\\": \\"$BAMPE\\", \
        \\"BAM_SE\\": \\"$BAMSE\\", \
        \\"PE_ALIGN_STATS\\": \\"$STATSPE\\", \
        \\"SE_ALIGN_STATS\\": \\"$STATSSE\\" }}" | \
        jq . > {output}
        '''


if config["params"]["alignment"]["strobealign"]["do"]:
    rule alignment_strobealign_all:
        input:
            expand(os.path.join(
                config["output"]["alignment"], "bam/strobealign/{sample}/{sample}.json"),
                sample=SAMPLES_ID_LIST)

else:
    rule alignment_strobealign_all:
        input:


rule alignment_all:
    input:
        rules.alignment_bowtie2_all.input,
        rules.alignment_strobealign_all.input
    

localrules:
    alignment_bowtie2_all,
    alignment_strobealign_all,
    alignment_all
