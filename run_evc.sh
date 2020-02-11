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
optional=${12}

USAGE="\nMissing input arguments..\n
USAGE:\trun_evc \\
	path/to/fastq/files \\
	output/directory \\
	path/to/sample.map \\
	email.for@notification \\
	reference_genome \\
	pon (INTERNAL_PON) \\
	gnomad_dbSNP \\
	known_indel_list \\
	base_recalibration_list \\
	max_walltime (hours only) \\
	queue \\
	precancer (optional)\n\n"
	
if [ -z "${11}" ]
then
	printf "$USAGE"
	exit 1
fi

mkdir -p ${out}/jobs/align
mkdir -p ${out}/jobs/refine
mkdir -p ${out}/jobs/pon
mkdir -p ${out}/jobs/strelka
mkdir -p ${out}/jobs/varscan
mkdir -p ${out}/jobs/mutect
mkdir -p ${out}/jobs/check_and_go

if [ -z "${12}" ]
then
	if [ ${optional} == "precancer" ]
	then	mkdir -p ${out}/jobs/postAlign
	fi
fi

cd $out/jobs/check_and_go
printf "cd ${out}/jobs/align\nfor f in *pbs;do qsub \$f|awk -v samp=\$f -F\".\" '{print \$1\"\\\t\"samp}'>>${out}/jobs/check_and_go/align_job_IDs.txt;done\n">start_align.sh
chmod +x start_align.sh
~/EnsembleVaraintCallingPipeline/align_check_template.sh $sampleF $out
~/EnsembleVaraintCallingPipeline/refine_check_template.sh $sampleF $out 

cd $out
cat $sampleF|tail -n+2|while read line;
do
sample=$(echo $line|cut -d ' ' -f1)
tumor=$(echo $line|cut -d ' ' -f2)
normal=$(echo $line|cut -d ' ' -f3)
type=$(echo $line|cut -d ' ' -f4)
~/EnsembleVaraintCallingPipeline/align_template.sh $email $sample $tumor $normal $ref $path $out $type $walltime $queue
~/EnsembleVaraintCallingPipeline/targetInterval_template.sh $email $sample $ref $out ${known_indel_list}
~/EnsembleVaraintCallingPipeline/refine_template.sh $email $sample $ref $out ${known_indel_list} ${base_recalibration_list} $walltime $queue
~/EnsembleVaraintCallingPipeline/pon_template.sh $email $sample $ref $out $walltime $queue
~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type $queue
~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out $queue
~/EnsembleVaraintCallingPipeline/mutect_template.sh $email $sample $ref $out $pon $type $dbSNP $queue

if [ -z "${12}" ]
then
	if [ ${optional} == "precancer" ]
	then	~/EnsembleVaraintCallingPipeline/postAlignment_template.sh $email $sample $ref $out ${known_indel_list} ${base_recalibration_list} $walltime $queue
	fi
fi
done
