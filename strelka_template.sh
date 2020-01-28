#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
type=$5
normal=${out}/${sample}/${sample}_normal_final.bam
tumor=${out}/${sample}/${sample}_tumor_final.bam

if [ ${queue} == "hotel" ]
then
	header="#!/bin/bash
	#PBS -q hotel
	#PBS -l nodes=1:ppn=8
	#PBS -l walltime=${walltime}:00:00
	#PBS -m bea
	#PBS -M ${email}
	#PBS -V 
	"
else
	header="#!/bin/bash
	#PBS -q home-alexandrov
	#PBS -l nodes=1:ppn=28:skylake
	#PBS -l walltime=${walltime}:00:00
	#PBS -m bea
	#PBS -M ${email}
	#PBS -V 
	"
fi
header="${header}""
#PBS -N EVC_strelka_${sample}
#PBS -e ${sample}_strelka.e
#PBS -o ${sample}_strelka.o
"

strelka_config_exome="configureStrelkaSomaticWorkflow.py --exome --referenceFasta $ref --normalBam $normal --tumorBam $tumor --runDir ${out}/${sample}/strelka"
strelka_config_genome="configureStrelkaSomaticWorkflow.py --referenceFasta $ref --normalBam $normal --tumorBam $tumor --runDir ${out}/${sample}/strelka"
runstrelka="python2 ${out}/${sample}/strelka/runWorkflow.py -m local -j \$(nproc)"

printf "$header">jobs/strelka/${sample}_strelka.pbs
echo source ~/.bashrc>>jobs/strelka/${sample}_strelka.pbs
echo source activate evc_strelka>>jobs/strelka/${sample}_strelka.pbs
echo mkdir -p ${out}/${sample}/strelka>>jobs/strelka/${sample}_strelka.pbs
echo cd ${out}/${sample}/strelka>>jobs/strelka/${sample}_strelka.pbs

echo 'echo creating strelka workflow at $(date)'>>jobs/strelka/${sample}_strelka.pbs
if [ $type == "exome" ]
then echo ${strelka_config_exome}>>jobs/strelka/${sample}_strelka.pbs
else echo ${strelka_config_genome}>>jobs/strelka/${sample}_strelka.pbs
fi
echo 'echo strelka workflow created at $(date)'>>jobs/strelka/${sample}_strelka.pbs

echo 'echo starting strelka at $(date)'>>jobs/strelka/${sample}_strelka.pbs
echo 'strelkaS=$SECONDS'>>jobs/strelka/${sample}_strelka.pbs
echo ${runstrelka}>>jobs/strelka/${sample}_strelka.pbs
echo 'strelkaT=$(($SECONDS - $strelkaS))'>>jobs/strelka/${sample}_strelka.pbs
echo "echo strelka took \$(echo a|awk '{print '\"\$strelkaT\"'/3600}') hours">>jobs/strelka/${sample}_strelka.pbs
echo 'gunzip results/variants/*gz'>>jobs/strelka/${sample}_strelka.pbs
