STEPS = ["raw"]
if TRIMMING_DO:
    STEPS += ["trimming"]
if RMHOST_DO:
    STEPS += ["rmhost"]

SAMPLESDIR = os.path.join(config["output"][STEPS[-1]])

if config["params"]["qcreport"]["do"]:
    rule qcreport_summary:
        input:
            expand(os.path.join(config["output"]["qcreport"], "{step}_stats.tsv"),
            step=STEPS)
        output:
            summary_l = os.path.join(config["output"]["qcreport"], "qc_stats_l.tsv"),
            summary_w = os.path.join(config["output"]["qcreport"], "qc_stats_w.tsv")
        priority:
            30
        threads:
            config["params"]["qcreport"]["seqkit"]["threads"]
        run:
            df = strainpi.merge(input, strainpi.parse, threads)
            df = strainpi.compute_host_rate(df, STEPS, SAMPLES_ID_LIST, allow_miss_samples=True, output=output.summary_l)
            strainpi.qc_summary_merge(df, output=output.summary_w)


    rule qcreport_plot:
        input:
            rules.qcreport_summary.output
        output:
            os.path.join(config["output"]["qcreport"], "qc_reads_num_barplot.pdf")
        priority:
            30
        run:
            df = strainpi.parse(input[0])
            strainpi.qc_bar_plot(df, "seaborn", output=output[0])


    rule qcreport_all:
        input:
            os.path.join(config["output"]["qcreport"], "qc_stats_l.tsv"),
            os.path.join(config["output"]["qcreport"], "qc_stats_w.tsv"),
            os.path.join(config["output"]["qcreport"], "qc_reads_num_barplot.pdf")

else:
    rule qcreport_summary:
        input:


    rule qcreport_plot:
        input:


    rule qcreport_all:
        input:


localrules:
    qcreport_summary,
    qcreport_plot,
    qcreport_all