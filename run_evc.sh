#!/bin/bash
email=$4
ref=/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa
path=$1
out=$2
sampleF=$3
knownIndels=/restricted/alexandrov-group/shared/Reference_Genomes/known_indels/resources_broad_hg38_v0_Homo_sapiens_assembly38.known_indels.vcf
dbSNP=/projects/ps-lalexandrov/shared/gnomAD/af-only-gnomad.hg38.vcf.gz
USAGE="\nMissing input arguments..\n
USAGE:\trun.sh \\
	path/to/project \\
	output/directory \\
	path/to/sample.map \\
	email for job notification \\
	\n\n"
if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ]
then printf "$USAGE"
else
mkdir -p ${out}/jobs/align
mkdir -p ${out}/jobs/refine
mkdir -p ${out}/jobs/pon
mkdir -p ${out}/jobs/strelka
mkdir -p ${out}/jobs/varscan
cd $out
cat $sampleF|tail -n+2|while read line;do
sample=$(echo $line|cut -d ' ' -f1)
tumor=$(echo $line|cut -d ' ' -f2)
normal=$(echo $line|cut -d ' ' -f3)
type=$(echo $line|cut -d ' ' -f4)
~/EnsembleVaraintCallingPipeline/align_template.sh $email $sample $tumor $normal $ref $path $out
~/EnsembleVaraintCallingPipeline/targetInterval_template.sh $email $sample $ref $out $knownIndels
~/EnsembleVaraintCallingPipeline/refine_template.sh $email $sample $ref $out $knownIndels $dbSNP
~/EnsembleVaraintCallingPipeline/pon_template.sh $email $sample $ref $out
~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type
~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out
done
#for f in jobs/*align*.pbs;do qsub $f;done
fi