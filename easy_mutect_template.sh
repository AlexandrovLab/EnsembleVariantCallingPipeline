#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
dbsnp=$5

pon=/restricted/alexandrov-group/shared/precancer_analysis/analysis_results/oral/olivier_analyzed_oral_benign/PON/PON.vcf.gz
normal=${out}/${sample}/${sample}_normal_final.bam
tumor=${out}/${sample}/${sample}_tumor_final.bam
template="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_mutectEASY_${sample}
#PBS -e ${sample}_mutecttEASY.e
#PBS -o ${sample}_mutecttEASY.o

source ~/.bashrc
source activate evc_main
mkdir -p ${out}/${sample}/mutectEASY
cd ${out}/${sample}/mutectEASY
"


printf "$template">jobs/mutectEASY/${sample}_mutectEASY.pbs

mutect_cmd="gatk Mutect2 --native-pair-hmm-threads $(nproc) --germline-resource $dbsnp --af-of-alleles-not-in-resource 0.00003125 --reference $ref --panel-of-normals $pon --input $normal --tumor-sample ${sample}_tumor_final --input $tumor --normal-sample ${sample}_normal_final --output ${sample}_mutect_unfiltered.vcf"
filter_cmd="filter_mutect_cmd = 'gatk FilterMutectCalls -V ${sample}_mutect_unfiltered.vcf -O ${sample}_mutect_filtered.vcf'"


echo 'echo starting mutect command at $date....'>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo 'mutectS=$SECONDS'>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo ${mutect_cmd}>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo 'mutectT=$(($SECONDS-$mutectS))'>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo 'echo mutect command took $mutectT seconds'>>jobs/mutectEASY/${sample}_mutectEASY.pbs

echo 'echo starting mutect filter at $date....'>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo 'MfilterS=$SECONDS'>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo ${filter_cmd}>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo 'MfilterT=$(($SECONDS-$MfilterS))'>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo 'echo mutect filter took $MfilterT seconds'>>jobs/mutectEASY/${sample}_mutectEASY.pbs
echo 'echo job finished at $date'>>jobs/mutectEASY/${sample}_mutectEASY.pbs
