#!/bin/bash
email=$1
sample=$2
ref=$3
knownIndels=$4
out=$5

header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
"
Tjobname="#PBS -N EVC_Trefine_${sample}
#PBS -e ${sample}_Trefine_2.e
#PBS -o ${sample}_Trefine_2.o
"
Njobname="#PBS -N EVC_Nrefine_${sample}
#PBS -e ${sample}_Nrefine_2.e
#PBS -o ${sample}_Nrefine_2.o
"
RTC_t="gatk3 -T RealignerTargetCreator -R $ref -I ${sample}_tumor_mkdp.bam --known ${knownIndels} -o ${sample}_tumor_realign_target.intervals -Xmx\$(free -h| grep Mem | awk '{print \$4}')"
RTC_n="gatk3 -T RealignerTargetCreator -R $ref -I ${sample}_normal_mkdp.bam --known ${knownIndels} -o ${sample}_normal_realign_target.intervals -Xmx\$(free -h| grep Mem | awk '{print \$4}')"

IR_t="gatk3 -T IndelRealigner -R $ref -known ${knownIndels} -targetIntervals \$(pwd -P)/${sample}_tumor_realign_target.intervals --noOriginalAlignmentTags -I ${sample}_tumor_mkdp.bam -o ${sample}_tumor_idra.bam"
IR_n="gatk3 -T IndelRealigner -R $ref -known ${knownIndels} -targetIntervals \$(pwd -P)/${sample}_normal_realign_target.intervals --noOriginalAlignmentTags -I ${sample}_normal_mkdp.bam -o ${sample}_normal_idra.bam"

printf "$header">jobs/refine/${sample}_Trefine_2.pbs
printf "${Tjobname}">>jobs/refine/${sample}_Trefine_2.pbs
printf "$header">jobs/refine/${sample}_Nrefine_2.pbs
printf "${Njobname}">>jobs/refine/${sample}_Nrefine_2.pbs
echo source ~/.bashrc>>jobs/refine/${sample}_Trefine_2.pbs
echo source activate evc_py3>>jobs/refine/${sample}_Trefine_2.pbs
echo source ~/.bashrc>>jobs/refine/${sample}_Nrefine_2.pbs
echo source activate evc_py3>>jobs/refine/${sample}_Nrefine_2.pbs
echo cd ${out}/${sample}_talign/>>jobs/refine/${sample}_Trefine_2.pbs
echo cd ${out}/${sample}_nalign/>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'echo starting RealignerTargetCreator at $(date)'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo starting RealignerTargetCreator at $(date)'>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'targetS=$SECONDS'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'targetS=$SECONDS'>>jobs/refine/${sample}_Nrefine_2.pbs
echo ${RTC_t}>>jobs/refine/${sample}_Trefine_2.pbs
echo ${RTC_n}>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'targetT=$(($SECONDS - $targetS))'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'targetT=$(($SECONDS - $targetS))'>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'echo target interval creation took $targetT seconds'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo target interval creation took $targetT seconds'>>jobs/refine/${sample}_Nrefine_2.pbs

echo 'echo job finished at $(date)'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo job finished at $(date)'>>jobs/refine/${sample}_Nrefine_2.pbs
