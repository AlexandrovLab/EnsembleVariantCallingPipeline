#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
KI1=$5
KI2=$6

header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_targetInterval_${sample}
#PBS -e ${sample}_targetInterval.e
#PBS -o ${sample}_targetInterval.o
"


RTC="gatk3 -T RealignerTargetCreator -R $ref -I ${sample}_tumor_mkdp.bam -I ${sample}_normal_mkdp.bam --known $KI1 --known $KI2 -o ${sample}_realign_target.intervals -Xmx\$(free -h| grep Mem | awk '{print \$4}')"
printf "$header">jobs/refine/${sample}_targetInterval.pbs

echo source ~/.bashrc>>jobs/refine/${sample}_targetInterval.pbs
echo source activate evc_gatk3>>jobs/refine/${sample}_targetInterval.pbs
echo cd ${out}/${sample}/>>jobs/refine/${sample}_targetInterval.pbs

echo 'echo starting RealignerTargetCreator at $(date)'>>jobs/refine/${sample}_targetInterval.pbs
echo 'targetS=$SECONDS'>>jobs/refine/${sample}_targetInterval.pbs
echo $RTC>>jobs/refine/${sample}_targetInterval.pbs
echo 'targetT=$(($SECONDS - $targetS))'>>jobs/refine/${sample}_targetInterval.pbs
echo 'echo target interval creation took $targetT seconds'>>jobs/refine/${sample}_targetInterval.pbs

echo cd ${out}/jobs/refine/>>jobs/refine/${sample}_targetInterval.pbs
echo qsub ${sample}_Nrefine_2.pbs>>jobs/refine/${sample}_targetInterval.pbs
echo qsub ${sample}_Trefine_2.pbs>>jobs/refine/${sample}_targetInterval.pbs
