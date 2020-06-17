#!/bin/bash
path=$1
out=$2
sampleF=$3
email=$4
ref=/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa
pon=/projects/ps-lalexandrov/shared/Reference_Genomes/TCGA_GDC_files/tumor_normal_PONs/MuTect2.PON.5210.vcf.gz
dbSNP=/restricted/alexandrov-group/shared/Reference_Genomes/dbSNP/af-only-gnomad.hg38_no_alt.vcf.gz

known_indel_list=/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/IndelRealignemnt_files.txt
base_recalibration_list=/restricted/alexandrov-group/shared/Reference_Genomes/alignment_refinement/BaseRecalibration_files.txt
USAGE="\nMissing input arguments..\n
USAGE:\trun_evc \\
	path/to/fastq/files \\
	output/directory \\
	path/to/sample.map \\
	email.for@notification \\
	precancer (optional)\n\n"
	
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
mkdir -p ${out}/jobs/muse
mkdir -p ${out}/jobs/check_and_go
mkdir -p ${out}/jobs/postAlign

cd $out/jobs/check_and_go
printf "cd ${out}/jobs/align\nfor f in *pbs;do qsub \$f|awk -v samp=\$f -F\".\" '{print \$1\"\\\t\"samp}'>>${out}/jobs/check_and_go/align_job_IDs.txt;done\n">start_align.sh
chmod +x start_align.sh
~/EnsembleVaraintCallingPipeline/align_check_template.sh $sampleF $out
~/EnsembleVaraintCallingPipeline/postalign_check_template.sh $sampleF $out 
~/EnsembleVaraintCallingPipeline/refine_check_template.sh $sampleF $out 

cd $out
cat $sampleF|tail -n+2|while read line;
do
sample=$(echo $line|cut -d ' ' -f1)
tumor=$(echo $line|cut -d ' ' -f2)
normal=$(echo $line|cut -d ' ' -f3)
type=$(echo $line|cut -d ' ' -f4)
purity=$(echo $line|cut -d ' ' -f8)
if [ $type == "exome" ]
then 
interval_list="/projects/ps-lalexandrov/shared/Reference_Genomes/interval_lists/GRCh38/wxs/whole_exome_illumina_coding_v1.Homo_sapiens_assembly38_canonical.targets.interval_list"
else
interval_list="/projects/ps-lalexandrov/shared/Reference_Genomes/interval_lists/GRCh38/wgs/wgs_calling_regions.v1.interval_list"
fi
~/EnsembleVaraintCallingPipeline/align_template.sh $email $sample $tumor $normal $ref $path $out $type
~/EnsembleVaraintCallingPipeline/targetInterval_template.sh $email $sample $ref $out ${known_indel_list}
~/EnsembleVaraintCallingPipeline/refine_template.sh $email $sample $ref $out ${known_indel_list} ${base_recalibration_list}
~/EnsembleVaraintCallingPipeline/pon_template.sh $email $sample $ref $out
~/EnsembleVaraintCallingPipeline/strelka_template.sh $email $sample $ref $out $type
~/EnsembleVaraintCallingPipeline/varscan_template.sh $email $sample $ref $out $purity
~/EnsembleVaraintCallingPipeline/mutect_template.sh $email $sample $ref $out $pon $type $dbSNP ${interval_list}
~/EnsembleVaraintCallingPipeline/muse_template.sh $email $sample $ref $out $type $dbSNP
~/EnsembleVaraintCallingPipeline/postAlignment_template.sh $email $sample $ref $out ${known_indel_list} ${base_recalibration_list}
done


