#!/bin/bash
email=$4
ref=/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa
path=$1
out=$2
sampleF=$3
known_indels="/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/Homo_sapiens_assembly38.known_indels.vcf /restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/Mills_and_1000G_gold_standard.indels.hg38.vcf"
base_recalibration="/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/Homo_sapiens_assembly38.known_indels.vcf /restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/Mills_and_1000G_gold_standard.indels.hg38.vcf /restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/Homo_sapiens_assembly38.dbsnp138.vcf /restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/1000G_phase1.snps.high_confidence.hg38.vcf"

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
mkdir -p ${out}/jobs/mutect
cd $out
cat $sampleF|tail -n+2|while read line;do
sample=$(echo $line|cut -d ' ' -f1)
tumor=$(echo $line|cut -d ' ' -f2)
normal=$(echo $line|cut -d ' ' -f3)
type=$(echo $line|cut -d ' ' -f4)
~/EnsembleVaraintCallingPipeline/align_template.sh $email $sample $tumor $normal $ref $path $out
~/EnsembleVaraintCallingPipeline/targetInterval_template.sh $email $sample $ref $out $KI1 $KI2
~/EnsembleVaraintCallingPipeline/refine_template.sh $email $sample $ref $out ${known_indels} ${base_recalibration}
~/EnsembleVaraintCallingPipeline/pon_template.sh $email $sample $ref $out
~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type
~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out
~/EnsembleVaraintCallingPipeline/mutect_template.sh $email $sample $ref $out $dbSNP $type
done
#for f in jobs/*align*.pbs;do qsub $f;done
fi
