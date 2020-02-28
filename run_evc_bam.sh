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


USAGE="\nMissing input arguments..\n
USAGE:\trun_evc \\
	path/to/bam/files \\
	output/directory \\
	path/to/sample.map \\
	email.for@notification \\
	reference_genome (fasta) \\
	pon (INTERNAL_PON) \\
	gnomad_dbSNP \\
	known_indel_list \\
	base_recalibration_list \\
	max_walltime (hours only) \\
	queue (hotel or home) \n\n"

	
if [ -z "${11}" ]
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
	sample=$(echo $line|cut -d ' ' -f1)
	tumor=$(echo $line|cut -d ' ' -f2)
	normal=$(echo $line|cut -d ' ' -f3)
	type=$(echo $line|cut -d ' ' -f4)
	echo $sample
	~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type $walltime $queue bam $path/$tumor $path/$normal
	~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out $walltime $queue bam $path/$tumor $path/$normal
	~/EnsembleVaraintCallingPipeline/muse_template.sh $email $sample $ref $out $type $dbSNP $walltime $queue bam $path/$tumor $path/$normal

done
