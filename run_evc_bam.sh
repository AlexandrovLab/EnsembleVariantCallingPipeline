#!/bin/bash

path=${1}
out=${2}
sampleF=${3}
email=${4}
ref=${5}
pon=${6}
dbSNP=${7}
walltime=${8}
queue=${9}
interval_list=${10}


USAGE="\nMissing input arguments..\n
USAGE:\trun_evc \\
	path/to/bam/files \\
	output/directory \\
	path/to/sample.map \\
	email.for@notification \\
	reference_genome (fasta) \\
	pon (INTERNAL_PON) \\
	gnomad_dbSNP \\
	max_walltime (hours only) \\
	queue (hotel or home) \\
	interval_list_file_for_mutect \n\n"

	
if [ -z "${9}" ]
then
	printf "$USAGE"
	exit 1
fi


mkdir -p ${out}/jobs/strelka
mkdir -p ${out}/jobs/varscan
mkdir -p ${out}/jobs/muse

cd $out
cat $sampleF|tail -n+2|while read line;
do
	if [ -z "$line" ]
	then
		exit 0
	fi
	
	sample=$(echo $line|cut -d ' ' -f1)
	tumor=$(echo $line|cut -d ' ' -f2)
	normal=$(echo $line|cut -d ' ' -f3)
	type=$(echo $line|cut -d ' ' -f4)
	echo $sample
	
	mkdir -p ${out}/${sample}
	if [ ! -f "${out}/${sample}/${sample}_tumor_final.bam" ]
	then
		ln -s ${path}/${tumor}.bam ${out}/${sample}/${sample}_tumor_final.bam
	fi
	
	if [ ! -f "${out}/${sample}/${sample}_normal_final.bam" ]
	then
		ln -s ${path}/${normal}.bam ${out}/${sample}/${sample}_normal_final.bam
	fi
	
	~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type $walltime $queue bam
	~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out $walltime $queue
	~/EnsembleVaraintCallingPipeline/muse_template.sh $email $sample $ref $out $type $dbSNP $walltime $queue
	~/EnsembleVaraintCallingPipeline/mutect_template.sh $email $sample $ref $out $pon $type $dbSNP $walltime $queue ${interval_list} $refine
done
