#!/bin/bash

path=${1}
out=${2}
sampleF=${3}
email=${4}
ref=${5}
pon=${6}
dbSNP=${7}
known_indel_list=${8}
base_recalibration_list=${9}
walltime=${10}
queue=${11}
interval_list=${12}
refine=${13}

USAGE="\nMissing input arguments..\n
USAGE:\trun_evc \\
	path/to/fastq/files \\
	output/directory \\
	path/to/sample.map \\
	email.for@notification \\
	path/to/reference_genome (fasta) \\
	pon (INTERNAL_PON) \\
	path/to/gnomad_dbSNP \\
	path/to/known_indel_list \\
	path/to/base_recalibration_list \\
	max_walltime (hours only) \\
	queue \\
	path/to/interval_list \\
	run refine? (yes or no) [default: no]\n\n"

	
if [ -z "${12}" ]
then
	printf "$USAGE"
	exit 1
fi

mkdir -p ${out}/jobs/align
mkdir -p ${out}/jobs/pon
mkdir -p ${out}/jobs/strelka
mkdir -p ${out}/jobs/varscan
mkdir -p ${out}/jobs/mutect
mkdir -p ${out}/jobs/muse
mkdir -p ${out}/jobs/check_and_go

if [ "$refine" == "yes" ]
then
	mkdir -p ${out}/jobs/refine
	~/EnsembleVaraintCallingPipeline/refine_check_template.sh $sampleF $out
else
	refine="no"
fi

cd $out/jobs/check_and_go
printf "cd ${out}/jobs/align\nfor f in *pbs;do qsub \$f|awk -v samp=\$f -F\".\" '{print \$1\"\\\t\"samp}'>>${out}/jobs/check_and_go/align_job_IDs.txt;done\n">start_align.sh
chmod +x start_align.sh
~/EnsembleVaraintCallingPipeline/align_check_template.sh $sampleF $out

cd $out
cat $sampleF|tail -n+2|while read line;
do
	sample=$(echo $line|cut -d ' ' -f1)
	tumor=$(echo $line|cut -d ' ' -f2)
	normal=$(echo $line|cut -d ' ' -f3)
	type=$(echo $line|cut -d ' ' -f4)
	~/EnsembleVaraintCallingPipeline/align_template.sh $email $sample $tumor $normal $ref $path $out $type $walltime $queue
	
	if [ "$refine" == "yes" ]
	then
	echo generating refinement output for the first sample...
	echo known indel is ${known_indel_list}
	echo base recalib is ${base_recalibration_list}
	echo walltime is ${base_recalibration_list} $walltime
		~/EnsembleVaraintCallingPipeline/targetInterval_template.sh $email $sample $ref $out ${known_indel_list} $queue
		~/EnsembleVaraintCallingPipeline/refine_template.sh $email $sample $ref $out ${known_indel_list} ${base_recalibration_list} $walltime $queue
	fi
	echo generating rest of the files for the first sample...
	~/EnsembleVaraintCallingPipeline/pon_template.sh $email $sample $ref $out $walltime $queue
	~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type $walltime $queue fastq $refine
	~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out $walltime $queue $refine
	~/EnsembleVaraintCallingPipeline/mutect_template.sh $email $sample $ref $out $pon $type $dbSNP $walltime $queue ${interval_list} $refine
  	~/EnsembleVaraintCallingPipeline/muse_template.sh $email $sample $ref $out $type $dbSNP $walltime $queue $refine


done
