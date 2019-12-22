#!/bin/bash
email=$4
ref=/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa
path=$1
out=$2
sampleF=$3
known_indel_list=/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/IndelRealignemnt_files.txt
base_recalibration_list=/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/BaseRecalibration_files.txt

dbSNP=/projects/ps-lalexandrov/shared/gnomAD/af-only-gnomad.hg38.vcf.gz
USAGE="\nMissing input arguments..\n
USAGE:\trun_evc \\
	path/to/fastq/files \\
	output/directory \\
	path/to/sample.map \\
	email.for@notification \n\n"
if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ]
then printf "$USAGE"
else
mkdir -p ${out}/jobs/align
mkdir -p ${out}/jobs/refine
mkdir -p ${out}/jobs/pon
mkdir -p ${out}/jobs/strelka
mkdir -p ${out}/jobs/varscan
mkdir -p ${out}/jobs/mutect
cd $out
cat $sampleF|tail -n+2|while read line;do
sample=$(echo $line|cut -d ' ' -f1)
tumor=$(echo $line|cut -d ' ' -f2)
normal=$(echo $line|cut -d ' ' -f3)
type=$(echo $line|cut -d ' ' -f4)
~/EnsembleVaraintCallingPipeline/align_template.sh $email $sample $tumor $normal $ref $path $out
~/EnsembleVaraintCallingPipeline/targetInterval_template.sh $email $sample $ref $out ${known_indel_list}
~/EnsembleVaraintCallingPipeline/refine_template.sh $email $sample $ref $out ${known_indel_list} ${base_recalibration_list}
~/EnsembleVaraintCallingPipeline/pon_template.sh $email $sample $ref $out
~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type
~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out
~/EnsembleVaraintCallingPipeline/mutect_template.sh $email $sample $ref $out $dbSNP $type
done
#for f in jobs/*align*.pbs;do qsub $f;done
fi
