#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
known_indels=$5
base_recalibration=$6

USAGE="PostAlignment_template.sh: not enough inputs...check script/n"
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]
then
	printf "$USAGE"
	exit 1
fi

header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=100:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_postAlign_${sample}
#PBS -e ${sample}_postAlign.e
#PBS -o ${sample}_postAlign.o
"
printf "$header">jobs/postAlign/${sample}_postAlign.pbs


#### Define Commands #####

# RealignerTargetCreator
RTC="gatk3 -T RealignerTargetCreator -R $ref -I ${sample}_tumor_mkdp.bam -I ${sample}_normal_mkdp.bam -o ${sample}_realign_target.intervals -Xmx\$(free -h| grep Mem | awk '{print \$4}')"
while read ki;
do
RTC=$(echo "${RTC} --known $ki")
done < <(cat ${known_indels})

# Base Recalibration
BR_t="gatk3 -T BaseRecalibrator -R $ref -I ${sample}_tumor_idra.bam -o ${sample}_tumor_bqsr.grp -Xmx20G"
BR_n="gatk3 -T BaseRecalibrator -R $ref -I ${sample}_normal_idra.bam -o ${sample}_normal_bqsr.grp -Xmx20G"
while read br;
do
BR_t=$(echo "${BR_t} --knownSites $br")
BR_n=$(echo "${BR_n} --knownSites $br")
done < <(cat ${base_recalibration})

# Indel Realignment
IR_t="gatk3 -T IndelRealigner -R $ref -targetIntervals ${sample}_realign_target.intervals --noOriginalAlignmentTags -I ${sample}_tumor_mkdp.bam -o ${sample}_tumor_idra.bam -Xmx20G"
IR_n="gatk3 -T IndelRealigner -R $ref -targetIntervals ${sample}_realign_target.intervals --noOriginalAlignmentTags -I ${sample}_normal_mkdp.bam -o ${sample}_normal_idra.bam -Xmx20G"
while read ki;
do
IR_t=$(echo "${IR_t} -known $ki")
IR_n=$(echo "${IR_n} -known $ki")
done < <(cat ${known_indels})

# Print Reads
PR_t="gatk3 -T PrintReads -R $ref -I ${sample}_tumor_idra.bam --BQSR ${sample}_tumor_bqsr.grp -o ${sample}_tumor_final.bam -Xmx20G"
PR_n="gatk3 -T PrintReads -R $ref -I ${sample}_normal_idra.bam --BQSR ${sample}_normal_bqsr.grp -o ${sample}_normal_final.bam -Xmx20G"

# Panel Of Normals
pon_cmd="gatk Mutect2 --independent-mates -R $ref --native-pair-hmm-threads \$(nproc) -I ${sample}_normal_final.bam --max-mnp-distance 0 -O ${sample}_PON.vcf.gz"
############################

echo source ~/.bashrc>>jobs/postAlign/${sample}_postAlign.pbs
echo source activate evc_gatk3>>jobs/postAlign/${sample}_postAlign.pbs
echo cd ${out}/${sample}/>>jobs/postAlign/${sample}_postAlign.pbs

## Create target interval ##
echo '########## Target Interval #########'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo starting RealignerTargetCreator at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'targetS=$SECONDS'>>jobs/postAlign/${sample}_postAlign.pbs
echo $RTC>>jobs/postAlign/${sample}_postAlign.pbs
echo 'targetT=$(($SECONDS - $targetS))'>>jobs/postAlign/${sample}_postAlign.pbs
echo "echo target interval creation took \$(echo a|awk '{print '\"\$targetT\"'/3600}') hours">>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo Target Interval Created at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs

## Refine Alignemnt for Normal ##
echo '########## Normal Refine #########'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo starting IndelRealigner at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'idraS=$SECONDS'>>jobs/postAlign/${sample}_postAlign.pbs
echo ${IR_n}>>jobs/postAlign/${sample}_postAlign.pbs
echo 'idraT=$(($SECONDS - $idraS))'>>jobs/postAlign/${sample}_postAlign.pbs
echo "echo Indel Realignemnt took \$(echo a|awk '{print '\"\$idraT\"'/3600}') hours">>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo starting BaseRecalibrator at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'barcS=$SECONDS'>>jobs/postAlign/${sample}_postAlign.pbs
echo ${BR_n}>>jobs/postAlign/${sample}_postAlign.pbs
echo 'barcT=$(($SECONDS - $barcS))'>>jobs/postAlign/${sample}_postAlign.pbs
echo "echo Base Recalibration took \$(echo a|awk '{print '\"\$barcT\"'/3600}') hours">>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo starting PrintReads at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'prS=$SECONDS'>>jobs/postAlign/${sample}_postAlign.pbs
echo ${PR_n}>>jobs/postAlign/${sample}_postAlign.pbs
echo 'prT=$(($SECONDS - $prS))'>>jobs/postAlign/${sample}_postAlign.pbs
echo "echo Printing Reads took \$(echo a|awk '{print '\"\$prT\"'/3600}') hours">>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo Normal refinement finished at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs

## Refine Alignemnt for Tumor ##
echo '########## Tumor Refine #########'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo starting IndelRealigner at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'idraS=$SECONDS'>>jobs/postAlign/${sample}_postAlign.pbs
echo ${IR_t}>>jobs/postAlign/${sample}_postAlign.pbs
echo 'idraT=$(($SECONDS - $idraS))'>>jobs/postAlign/${sample}_postAlign.pbs
echo "echo Indel Realignemnt took \$(echo a|awk '{print '\"\$idraT\"'/3600}') hours">>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo starting BaseRecalibrator at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'barcS=$SECONDS'>>jobs/postAlign/${sample}_postAlign.pbs
echo ${BR_t}>>jobs/postAlign/${sample}_postAlign.pbs
echo 'barcT=$(($SECONDS - $barcS))'>>jobs/postAlign/${sample}_postAlign.pbs
echo "echo Base Recalibration took \$(echo a|awk '{print '\"\$barcT\"'/3600}') hours">>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo starting PrintReads at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'prS=$SECONDS'>>jobs/postAlign/${sample}_postAlign.pbs
echo ${PR_t}>>jobs/postAlign/${sample}_postAlign.pbs
echo 'prT=$(($SECONDS - $prS))'>>jobs/postAlign/${sample}_postAlign.pbs
echo "echo Printing Reads took \$(echo a|awk '{print '\"\$prT\"'/3600}') hours">>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo Tumor refinement finished at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs

## Panel of Normals ##
echo '########## Panel of Normals #########'>>jobs/postAlign/${sample}_postAlign.pbs
echo 'ponT=$(($SECONDS - $ponS))'>>jobs/postAlign/${sample}_postAlign.pbs
echo "echo generating PON vcf took \$(echo a|awk '{print '\"\$ponT\"'/3600}') hours">>jobs/postAlign/${sample}_postAlign.pbs
echo 'echo PON finished at $(date)'>>jobs/postAlign/${sample}_postAlign.pbs
