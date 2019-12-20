#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
#type=$5
normal=${out}/${sample}/${sample}_normal_final.bam
tumor=${out}/${sample}/${sample}_tumor_final.bam
template="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_mutect_${sample}
#PBS -e ${sample}_mutect.e
#PBS -o ${sample}_mutect.o

source ~/.bashrc
source activate evc_main
mkdir -p ${out}/${sample}/mutect
cd ${out}/${sample}/mutect
"

mutect_cmd="gatk Mutect2 -R $ref -I tumor.bam -germline-resource $dbSNP -pon panel_of_normals.vcf --f1r2-tar-gz ${sample}_f1r2.tar.gz -O ${sample}_unfiltered.vcf"
   
mutect_orientation_2="gatk LearnReadOrientationModel -I ${sample}_f1r2.tar.gz -O ${sample}_read-orientation-model.tar.gz"

mutect_contamin_1="gatk GetPileupSummaries -I tumor.bam -V chr17_small_exac_common_3_grch38.vcf.gz -L chr17_small_exac_common_3_grch38.vcf.gz -O getpileupsummaries.table"

mutect_contamin_2="gatk CalculateContamination -I getpileupsummaries.table -tumor-segmentation segments.table -O calculatecontamination.table"

mutect_filter="gatk FilterMutectCalls -V ${sample}_unfiltered.vcf [--tumor-segmentation segments.table] --contamination-table contamination.table] --ob-priors ${sample}_read-orientation-model.tar.gz -O ${sample}_filtered.vcf"
