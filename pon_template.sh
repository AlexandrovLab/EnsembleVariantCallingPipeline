#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
walltime=${5}
queue=${6}



if [ ${queue} == "hotel" ]
then
	header="#!/bin/bash
#PBS -q hotel
#PBS -l nodes=1:ppn=7
#PBS -l walltime=${walltime}:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V\n"
else
	header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=7:skylake
#PBS -l walltime=${walltime}:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V\n"
fi

header="${header}""
#PBS -N EVC_pon_${sample}
#PBS -e ${sample}_pon.e
#PBS -o ${sample}_pon.o
"

pon_1="gatk Mutect2 --independent-mates -R $ref --native-pair-hmm-threads \$(nproc) -I ${sample}_normal_final.bam --max-mnp-distance 0 -O ${sample}_PON.vcf.gz"


printf "$header">jobs/pon/${sample}_pon.pbs
echo source ~/.bashrc>>jobs/pon/${sample}_pon.pbs
echo source activate evc_main>>jobs/pon/${sample}_pon.pbs
echo cd ${out}/${sample}/>>jobs/pon/${sample}_pon.pbs



echo 'echo starting PanelOfNormals at $(date)'>>jobs/pon/${sample}_pon.pbs
echo 'ponS=$SECONDS'>>jobs/pon/${sample}_pon.pbs
echo ${pon_1}>>jobs/pon/${sample}_pon.pbs
echo 'ponT=$(($SECONDS - $ponS))'>>jobs/pon/${sample}_pon.pbs
echo "echo generating PON vcf took \$(echo a|awk '{print '\"\$ponT\"'/3600}') hours">>jobs/pon/${sample}_pon.pbs
