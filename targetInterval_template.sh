#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
known_indels=$5
USAGE="align_template.sh: not enough inputs...check script/n"
if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ] || [ "$5" == "" ]
then printf "$USAGE"
else
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

RTC="gatk3 -T RealignerTargetCreator -R $ref -I ${sample}_tumor_mkdp.bam -I ${sample}_normal_mkdp.bam -o ${sample}_realign_target.intervals -Xmx\$(free -h| grep Mem | awk '{print \$4}')"
while read ki;
do
RTC=$(echo "${RTC} --known $ki")
done < <(cat ${known_indels})

printf "$header">jobs/refine/${sample}_targetInterval.pbs

echo source ~/.bashrc>>jobs/refine/${sample}_targetInterval.pbs
echo source activate evc_gatk3>>jobs/refine/${sample}_targetInterval.pbs
echo cd ${out}/${sample}/>>jobs/refine/${sample}_targetInterval.pbs

## Create target interval ##
echo 'echo starting RealignerTargetCreator at $(date)'>>jobs/refine/${sample}_targetInterval.pbs
echo 'targetS=$SECONDS'>>jobs/refine/${sample}_targetInterval.pbs
echo $RTC>>jobs/refine/${sample}_targetInterval.pbs
echo 'targetT=$(($SECONDS - $targetS))'>>jobs/refine/${sample}_targetInterval.pbs
echo "echo target interval creation took $(echo a|awk '{print '"$targetT"'/3600}') hours">>jobs/refine/${sample}_targetInterval.pbs

## autosubmit the rest of refinement process ##
echo cd ${out}/jobs/refine/>>jobs/refine/${sample}_targetInterval.pbs
echo qsub ${sample}_Nrefine.pbs>>jobs/refine/${sample}_targetInterval.pbs
echo qsub ${sample}_Trefine.pbs>>jobs/refine/${sample}_targetInterval.pbs
fi
