# EnsembleVariantCallingPipeline
*The mutect and filtering portion is still in development...*


**FIRST TIME SETUP**

1. Clone the directory to your home on TSCC
2. Run the setup_env.sh script.


**TO RUN THE PIPELINE**
```
run_evc [args]
```
which will create a jobs/ directory in the output directory, the pipeline works through manually submitting the jobs at each stage.

Arguments:
```
run_evc \
	path/to/fastq/files \
	output/directory \
	path/to/sample.map \
	email.for@notification \
	reference_genome (fasta) \
	pon (INTERNAL_PON) \
	gnomad_dbSNP \
	known_indel_list \
	base_recalibration_list \
	max_walltime (hours only) \
	queue (hotel or home) \
	interval_list_for_mutect
```

**Running the pipeline starting with a bam file:**
```
run_evc_bam [args]
```
This works identically to run_evc, except it takes input bam files and only runs variant calling.

Arguments:
```
run_evc_bam \
	path/to/bam/files \
	output/directory \
	path/to/sample.map \
	email.for@notification \
	reference_genome (fasta) \
	pon (INTERNAL_PON) \
	gnomad_dbSNP \
	max_walltime (hours only) \
	queue (hotel or home) \
	interval_list_for_mutect
```



One shall submit the jobs at each stage step by step: (DO NOT move to the next step until the previous step is finished and verified.)

1. Both the *Nalign_1.pbs* and *Talign_1.pbs* under jobs/align/
2. The *targetInterval.pbs* under jobs/refine/ (when this is finished, the corresponding *Nrefine_2.pbs* and *Trefine_2.pbs* will be submitted automatically)
3. Scripts under jobs/pon/, jobs/strelka/ and jobs/varscan/ can all be submitted simutaniously at this point.
