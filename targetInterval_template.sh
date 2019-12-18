#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
knownIndels=$5

header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_targetInterval_${sample}
#PBS -e ${sample}_Trefine_2.e
#PBS -o ${sample}_Trefine_2.o
"


RTC_t="gatk3 -T RealignerTargetCreator -R $ref -I ${sample}_tumor_mkdp.bam --known ${knownIndels} -o ${sample}_tumor_realign_target.intervals -Xmx\$(free -h| grep Mem | awk '{print \$4}')"
RTC_n="gatk3 -T RealignerTargetCreator -R $ref -I ${sample}_normal_mkdp.bam --known ${knownIndels} -o ${sample}_normal_realign_target.intervals -Xmx\$(free -h| grep Mem | awk '{print \$4}')"

printf "$header">jobs/refine/${sample}_targetInterval.pbs

echo source ~/.bashrc>>jobs/refine/${sample}_targetInterval.pbs
echo source activate evc_py3>>jobs/refine/${sample}_targetInterval.pbs
echo cd ${out}/${sample}/>>jobs/refine/${sample}_targetInterval.pbs



echo 'echo starting RealignerTargetCreator at $(date)'>>jobs/refine/${sample}_targetInterval.pbs
echo 'targetS=$SECONDS'>>jobs/refine/${sample}_targetInterval.pbs
echo ${RTC_t}>>jobs/refine/${sample}_targetInterval.pbs
echo 'targetT=$(($SECONDS - $targetS))'>>jobs/refine/${sample}_targetInterval.pbs
echo ${RTC_n}>>jobs/refine/${sample}_targetInterval.pbs
echo 'targetN=$(($SECONDS - $targetS))'>>jobs/refine/${sample}_targetInterval.pbs
echo 'echo target interval creation took $targetT seconds for tumor'>>jobs/refine/${sample}_targetInterval.pbs
echo 'echo target interval creation took $targetN seconds for normal'>>jobs/refine/${sample}_targetInterval.pbs
