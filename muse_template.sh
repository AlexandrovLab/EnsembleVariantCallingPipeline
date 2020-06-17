#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
type=$5
dbSNP=$6

normal=${out}/${sample}/${sample}_normal_final.bam
tumor=${out}/${sample}/${sample}_tumor_final.bam

header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=7:skylake
#PBS -l walltime=100:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_MuSE_${sample}
#PBS -e ${sample}_MuSE.e
#PBS -o ${sample}_MuSE.o
"

## Defining the commmands
muse_cmd="MuSE call -O ${out}/${sample}/muse/${sample} -f $ref $tumor $normal"
if [ $type == "exome" ]
then muse_sump_cmd="MuSE sump -I ${out}/${sample}/muse/${sample}.MuSE.txt -E -O ${sample}.vcf -D $dbSNP"
else muse_sump_cmd="MuSE sump -I ${out}/${sample}/muse/${sample}.MuSE.txt -G -O ${sample}.vcf -D $dbSNP"
fi

## Writing the scripts
printf "$header">jobs/muse/${sample}_muse.pbs
echo mkdir -p ${out}/${sample}/muse>>jobs/muse/${sample}_muse.pbs
echo cd ${out}/${sample}/muse>>jobs/muse/${sample}_muse.pbs

echo 'echo === Starting MuSE on sample' ${sample} 'at $(date)==='>>jobs/muse/${sample}_muse.pbs
echo 'echo creating .MuSE.txt file at $(date)'>>jobs/muse/${sample}_muse.pbs
echo 'museS=$SECONDS'>>jobs/muse/${sample}_muse.pbs
echo ${muse_cmd}>>jobs/muse/${sample}_muse.pbs
echo 'museT=$(($SECONDS - $museS))'>>jobs/muse/${sample}_muse.pbs
echo "echo creating .MuSE.txt took \$(echo a|awk '{print '\"\$museT\"'/3600}') hours">>jobs/muse/${sample}_muse.pbs
echo 'echo .MuSE.txt file created at $(date)'>>jobs/muse/${sample}_muse.pbs

echo 'echo starting MuSE sump at $(date)'>>jobs/muse/${sample}_muse.pbs
echo 'MuSEsumpS=$SECONDS'>>jobs/muse/${sample}_muse.pbs
echo ${muse_sump_cmd}>>jobs/muse/${sample}_muse.pbs
echo 'MuSEsumpT=$(($SECONDS - $MuSEsumpS))'>>jobs/muse/${sample}_muse.pbs
echo "echo muse took \$(echo a|awk '{print '\"\$MuSEsumpT\"'/3600}') hours">>jobs/muse/${sample}_muse.pbs
