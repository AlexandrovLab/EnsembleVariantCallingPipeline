# EnsembleVaraintCallingPipeline
*First built in December 2019, EVC is the new bash based version of the previous Consensus Variant Calling pipeline. The mutect and filtering portion is still in development...*


**FIRST TIME SETUP**

1. Clone the directory to your home on TSCC
2. Run the setup_env.sh script.


**TO RUN THE PIPELINE**
```
run_evc [args]
```
which will create a jobs/ directory in the output directory, the pipeline works through manually submitting the jobs at each stage.

Current arguments are
```
run_evc
path/to/fastq/files \
output/directory \
path/to/sample.map \
email_for_job@notification \
```
This is the simplified version for conveniently submitting precancer WES jobs aligning to GRCh38. More args will be required in the future.


One shall submit the jobs at each stage step by step: (DO NOT move to the next step until the previous step is finished and verified.)

1. Both the *Nalign_1.pbs* and *Talign_1.pbs* under jobs/align/
2. The *targetInterval.pbs* under jobs/refine/ (when this is finished, the corresponding *Nrefine_2.pbs* and *Trefine_2.pbs* will be submitted automatically)
3. Scripts under jobs/pon/, jobs/strelka/ and jobs/varscan/ can all be submitted simutaniously at this point.
