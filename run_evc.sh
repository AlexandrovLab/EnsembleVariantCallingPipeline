#!/bin/bash
path=$1
out=$2
sampleF=$3
email=$4
ref=/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa
pon=/restricted/alexandrov-group/shared/precancer_analysis/analysis_results/oral/olivier_analyzed_oral_benign/PON/PON.vcf.gz
dbSNP=/projects/ps-lalexandrov/shared/gnomAD/af-only-gnomad.hg38.vcf.gz

known_indel_list=/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/IndelRealignemnt_files.txt
base_recalibration_list=/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/BaseRecalibration_files.txt
USAGE="\nMissing input arguments..\n
USAGE:\trun_evc \\
	path/to/fastq/files \\
	output/directory \\
	path/to/sample.map \\
	email.for@notification \n\n"
	
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]
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

if [ $5 == "precancer" ]
then
	mkdir -p ${out}/jobs/postAlign
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
~/EnsembleVaraintCallingPipeline/align_template.sh $email $sample $tumor $normal $ref $path $out $type
~/EnsembleVaraintCallingPipeline/targetInterval_template.sh $email $sample $ref $out ${known_indel_list}
~/EnsembleVaraintCallingPipeline/refine_template.sh $email $sample $ref $out ${known_indel_list} ${base_recalibration_list}
~/EnsembleVaraintCallingPipeline/pon_template.sh $email $sample $ref $out
~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type
~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out
~/EnsembleVaraintCallingPipeline/mutect_template.sh $email $sample $ref $out $pon $type $dbSNP

if [ $5 == "precancer" ] 
then
	~/EnsembleVaraintCallingPipeline/postAlignment_template.sh $email $sample $ref $out ${known_indel_list} ${base_recalibration_list}
fi

done


