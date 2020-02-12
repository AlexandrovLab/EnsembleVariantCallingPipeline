#!/bin/bash
path=${1}
out=${2}
sampleF=${3}
email=${4}
ref="/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa"
pon="/restricted/alexandrov-group/shared/precancer_analysis/analysis_results/oral/olivier_analyzed_oral_benign/PON/PON.vcf.gz"
dbSNP="/projects/ps-lalexandrov/shared/gnomAD/af-only-gnomad.hg38.vcf.gz"
known_indel_list="/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/IndelRealignemnt_files.txt"
base_recalibration_list="/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/BaseRecalibration_files.txt"
walltime=500
queue="home"
optional="precancer"

USAGE="\nMissing input arguments..\n
USAGE:\trun_evc \\
	path/to/fastq/files \\
	output/directory \\
	path/to/sample.map \\
	email.for@notification"
	
if [ -z "${11}" ]
then
	printf "$USAGE"
	exit 1
fi

run_evc ${path} ${out} ${sampleF} ${email} ${ref} ${pon} ${dbSNP} ${known_indel_list} ${base_recalibration_list} ${walltime} ${queue} ${optional}