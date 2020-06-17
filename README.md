*__Note:__ This pipeline was designed to run on the Triton Shared Compute Cluster (TSCC) at University of California - San Diego. Running it elsewhere will require modifying the source code.*

# EnsembleVariantCallingPipeline
The EnsembleVariantCallingPipeline takes files in FASTQ or BAM format and performs SNV variant calling from 4 variant callers ([Mutect2](https://gatk.broadinstitute.org/hc/en-us/articles/360037593851-Mutect2), [Strelka](https://doi.org/10.1038/s41592-018-0051-x), [Varscan2](http://doi.org/10.1101/gr.129684.111), [MuSE](https://doi.org/10.1186/s13059-016-1029-6)) and indel variant calling from 3 variant callers ([Mutect2](https://gatk.broadinstitute.org/hc/en-us/articles/360037593851-Mutect2), [Strelka](https://doi.org/10.1038/s41592-018-0051-x), [Varscan2](http://doi.org/10.1101/gr.129684.111)).

# Pipeline structure


### First time setup

1. Clone the directory
```
git clone https://github.com/AlexandrovLab/EnsembleVaraintCallingPipeline.git
cd EnsembleVaraintCallingPipeline/
```

2. Run the setup_env.sh script.
```
bash setup_env.sh
```

## Running the pipeline from fastq
_DO NOT_ move on if the previous step is still running. Each step must finish completely before moving on to the next step.

<ol>
<li><b> Generate project directory structure. (takes <2 minutes)</b> 
	
Run `run_evc` to create the `jobs` directory in the output directory. The pipeline will generate `.pbs` files for you to manually submit at each stage.

```
run_evc \
	path/to/fastq/files \
	output/directory \
	path/to/sample.map \
	email.for@notification \
	reference_genome (fasta) \
	pon (INTERNAL_PON or provide a PON for Mutect) \
	gnomad_dbSNP \
	known_indel_list \
	base_recalibration_list \
	max_walltime (hours only) \
	queue (hotel or home) \
	interval_list_for_mutect \
	Optional: run refine? (yes or no) [default: no]
```

</li>
<li> <b>Alignment (takes 10 minutes to several hours depending on job queue traffic and the size of your fastq files)</b>
	
Performs alignment with bwa-mem and marks duplicates caused by PCR with Picard's (GATK's) MarkDuplicates.

<ol>
<li> Navigate to the <code>jobs/align</code> directory in the output directory specified earlier. This directory contains the <code>.pbs</code> scripts used to run alignment on your fastq samples on TSCC. </li>

<li> Submit all alignment jobs to the job queue. 

```
for pbs_file in *.pbs; do qsub ${pbs_file}; done
```

This script will generate directories and perform alignment for each of your samples directly under `output_dir`. Within each of these, the script will generate tumor and normal `_raw.bam` files and then tumor and normal `_mkdp.bam` files.
</li> 

<li> Check that your aligned `.bam` files were generated properly. A quick method of checking the integrity of every bam file quickly is by running `samtools quickcheck` on the `.bam` files (*Note: empty output means there were no errors*). Here is a script to quickly check all of your files:

```
output_dir=[your output directory]
for f in ${output_dir}/*/*_mkdp.bam; do echo Checking ${f}: ; samtools quickcheck $f; done
```

</li></ol></li>


<li><b>(Optional) Refine alignment (takes several hours)</b>

You might want to skip this step if you believe your fastq files are of high quality since this step takes a long time to run. If you originally ran <code>run_evc</code> with refinement disabled, you can still run refinement by rerunning <code>run_evc</code> with the refinement option enabled.
	
<ol>
<li> Navigate to the <code>jobs/refine</code> directory.</li>
<li> Submit all <code>_targetInterval.pbs</code> files to job queue. 

```
for pbs_file in *_targetInterval.pbs; do qsub ${pbs_file}; done
```

This script will subsequently submit the <code>_Trefine.pbs</code> and <code>_Nrefine.pbs</code> files.
</li>
<li> Once finished, you can check the refined bam files, which are named <code>_final.bam</code>, using the same program as after alignment <code>samtools quickcheck</code>.

```
output_dir=[your output directory]
for f in ${output_dir}/*/*_final.bam; do echo Checking ${f}: ; samtools quickcheck $f; done
```

</li></ol>

<li> <b>Generating the panel of normals (takes about 1 hour) - WIP. Does not work yet. Please pass in your own panel of normals or use an empty file as a placeholder.</b>
	
The [panel of normals (PON)](https://gatk.broadinstitute.org/hc/en-us/articles/360035890631-Panel-of-Normals-PON-#:~:text=A%20Panel%20of%20Normal%20or,PON%20will%20be%20generated%20differently.) is useful in filtering out sequencing errors caused by limitations specific to the sequencing machine used. By comparing all normal samples in a batch that used the same sequening machine, this can identify recurrent mutations caused by technical artifacts from the machine. It can either be passed in through <code>run_evc</code> or generated from the bam files. The file is required to run Mutect2.
<ol>
<li> Navigate to the <code>jobs/pon</code> directory. </li>
<li> Submit all <code>_pon.pbs</code> jobs to the job queue.

```
for pbs_file in *_pon.pbs; do qsub ${pbs_file}; done
```

</li>
<li> Combine all individual pons into a merged pon 

```
TODO: add code
```

</li></ol></li>

<li><b> Run variant calling (takes several hours) </b>

The order of running the variant callers does not matter since they work independently. Filtering the <code>.vcf</code> files after variant calling is highly recommended.

<ul>
<li> <a href="https://gatk.broadinstitute.org/hc/en-us/articles/360037593851-Mutect2">Mutect2</a>

Submit the <code>_mutect.pbs</code> files under <code>jobs/mutect</code>.

```
cd jobs/mutect
for pbs_file in *_mutect.pbs; do qsub ${pbs_file}; done
```

</li>

<li> <a href="https://github.com/Illumina/strelka">Strelka2</a>

Submit the <code>_strelka.pbs</code> files under <code>jobs/strelka</code>.

```
cd jobs/strelka
for pbs_file in *_strelka.pbs; do qsub ${pbs_file}; done
```

</li>

<li> <a href="https://github.com/dkoboldt/varscan">Varscan2</a>
	
Submit the <code>_varscan.pbs</code> files under <code>jobs/varscan</code>.

```
cd jobs/varscan
for pbs_file in *_varscan.pbs; do qsub ${pbs_file}; done
```

</li>

<li> <a href="https://github.com/danielfan/MuSE">MuSE</a>
	
Submit the <code>_muse.pbs</code> files under <code>jobs/muse</code>.

```
cd jobs/muse
for pbs_file in *_muse.pbs; do qsub ${pbs_file}; done
```

</li></ul></li></ol>

## Running the pipeline starting with a bam file
_DO NOT_ move on if the previous step is still running. Each step must finish completely before moving on to the next step.

<ol>
<li><b> Generate project directory structure. (takes <2 minutes)</b>

Run `run_evc_bam` to create the `jobs` directory in the output directory. The pipeline will generate `.pbs` files for you to manually submit at each stage.

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

</li>
<li><b> Follow the "Running from fastq" pipeline starting at step 5: Run variant calling</b>
</li>

</ol>

One shall submit the jobs at each stage step by step: (DO NOT move to the next step until the previous step is finished and verified.)

1. Both the *Nalign_1.pbs* and *Talign_1.pbs* under jobs/align/
2. The *targetInterval.pbs* under jobs/refine/ (when this is finished, the corresponding *Nrefine_2.pbs* and *Trefine_2.pbs* will be submitted automatically)
3. Scripts under jobs/pon/, jobs/strelka/ and jobs/varscan/ can all be submitted simutaniously at this point.
