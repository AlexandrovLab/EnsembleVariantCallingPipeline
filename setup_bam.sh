#!/bin/bash

path=${1}
out=${2}
sample=${3}
tumor=${4}
normal=${5}

USAGE="\nMissing input arguments..\n
USAGE:\tsetup_bam.sh \\
	path/to/bam/files \\
	output/directory \\
	sample_name \\
	tumor_name \\
	normal_name \n\n"

	
if [ -z "${5}" ]
then
	printf "$USAGE"
	exit 1
fi


mkdir $sample
cp ${path}/${tumor}.bam ${out}/${sample}/${sample}_tumor_final.bam
cp ${path}/${normal}.bam ${out}/${sample}/${sample}_normal_final.bam

