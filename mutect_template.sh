#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
pon=$5
type=$6
dbSNP=$7
intervalList=$8

# decide --af-of-alleles-not-in-resource based on exome or genome data type
if [ $type == "exome" ]
then af=0.0000025
else af=0.00003125
fi

normal=${out}/${sample}/${sample}_normal_final.bam
tumor=${out}/${sample}/${sample}_tumor_final.bam

template="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=1:skylake
#PBS -l walltime=300:00:00
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

######## Commands ########
mutect_cmd="gatk Mutect2 -independent-mates -R $ref -pon $pon --germline-resource $dbSNP --native-pair-hmm-threads \$(nproc) --af-of-alleles-not-in-resource $af --f1r2-tar-gz ${sample}_f1r2.tar.gz --normal-sample ${sample}_normal --input $normal --tumor-sample ${sample}_tumor --input $tumor -O ${sample}_mutect2_unfiltered.vcf"
  
mutect_orientation="gatk LearnReadOrientationModel -I ${sample}_f1r2.tar.gz -O ${sample}_read-orientation-model.tar.gz"

mutect_pileupsum="gatk GetPileupSummaries --java-options \"-Xmx\$(free -h| grep Mem | awk '{split(\$7,a,\"G\");print a[1]-5\"G\"}')\" -I ${out}/${sample}/${sample}_tumor_final.bam -V $dbSNP -L $intervalList -O ${sample}_getpileupsummaries.table"

mutect_contamin="gatk CalculateContamination -I ${sample}_getpileupsummaries.table -tumor-segmentation ${sample}_segments.table -O ${sample}_contamination.table"

mutect_filter="gatk FilterMutectCalls -R $ref -V ${sample}_mutect2_unfiltered.vcf --tumor-segmentation ${sample}_segments.table --contamination-table ${sample}_contamination.table --ob-priors ${sample}_read-orientation-model.tar.gz -O ${sample}_mutect2_filtered.vcf"
###########################

printf "$template">jobs/mutect/${sample}_mutect.pbs
echo 'echo === Starting MuTect2 on sample' ${sample} 'at $(date)==='>>jobs/mutect/${sample}_mutect.pbs
echo 'echo starting mutect command at $(date)....'>>jobs/mutect/${sample}_mutect.pbs
echo 'mutectS=$SECONDS'>>jobs/mutect/${sample}_mutect.pbs
echo ${mutect_cmd}>>jobs/mutect/${sample}_mutect.pbs
echo 'mutectT=$(($SECONDS-$mutectS))'>>jobs/mutect/${sample}_mutect.pbs
echo "echo mutect command took \$(echo a|awk '{print '\"\$mutectT\"'/3600}') hours">>jobs/mutect/${sample}_mutect.pbs

echo 'echo starting Read Orientation at $(date)....'>>jobs/mutect/${sample}_mutect.pbs
echo 'readorientationtS=$SECONDS'>>jobs/mutect/${sample}_mutect.pbs
echo ${mutect_orientation}>>jobs/mutect/${sample}_mutect.pbs
echo 'readorientationtT=$(($SECONDS-$readorientationtS))'>>jobs/mutect/${sample}_mutect.pbs
echo "echo read orientation took \$(echo a|awk '{print '\"\$readorientationtT\"'/3600}') hours">>jobs/mutect/${sample}_mutect.pbs

echo 'echo starting GetPileupSummaries at $(date)....'>>jobs/mutect/${sample}_mutect.pbs
echo 'ct1S=$SECONDS'>>jobs/mutect/${sample}_mutect.pbs
echo ${mutect_pileupsum}>>jobs/mutect/${sample}_mutect.pbs
echo 'ct1T=$(($SECONDS-$ct1S))'>>jobs/mutect/${sample}_mutect.pbs
echo "echo GetPileupSummaries took \$(echo a|awk '{print '\"\$ct1T\"'/3600}') hours">>jobs/mutect/${sample}_mutect.pbs

echo 'echo starting calculating contamination at $(date)....'>>jobs/mutect/${sample}_mutect.pbs
echo 'ct2S=$SECONDS'>>jobs/mutect/${sample}_mutect.pbs
echo ${mutect_contamin}>>jobs/mutect/${sample}_mutect.pbs
echo 'ct2T=$(($SECONDS-$ct2S))'>>jobs/mutect/${sample}_mutect.pbs
echo "echo calculating contamination took \$(echo a|awk '{print '\"\$ct2T\"'/3600}') hours">>jobs/mutect/${sample}_mutect.pbs

echo 'echo starting mutect filter at $(date)....'>>jobs/mutect/${sample}_mutect.pbs
echo 'MfilterS=$SECONDS'>>jobs/mutect/${sample}_mutect.pbs
echo ${mutect_filter}>>jobs/mutect/${sample}_mutect.pbs
echo 'MfilterT=$(($SECONDS-$MfilterS))'>>jobs/mutect/${sample}_mutect.pbs
echo "echo mutect filtering took \$(echo a|awk '{print '\"\$MfilterT\"'/3600}') hours">>jobs/mutect/${sample}_mutect.pbs
echo 'echo job finished at $(date)'>>jobs/mutect/${sample}_mutect.pbs
