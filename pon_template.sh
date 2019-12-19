#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4

header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_pon_${sample}
#PBS -e ${sample}_pon.e
#PBS -o ${sample}_pon.o
"

pon_1="gatk Mutect2 -R $ref --native-pair-hmm-threads \$(nproc) -I ${sample}_normal_final.bam --max-mnp-distance 0 -O {sample}_PON.vcf.gz"


printf "$header">jobs/pon/${sample}_pon_3.pbs
echo source ~/.bashrc>>jobs/pon/${sample}_pon_3.pbs
echo source activate cvc_py3>>jobs/pon/${sample}_pon_3.pbs
echo cd ${out}/${sample}/>>jobs/pon/${sample}_pon_3.pbs

echo 'echo starting PanelOfNormals at $(date)'>>jobs/pon/${sample}_pon_3.pbs
echo 'ponS=$SECONDS'>>jobs/pon/${sample}_pon_3.pbs
echo ${pon_1}>>jobs/pon/${sample}_pon_3.pbs
echo 'ponT=$(($SECONDS - $ponS))'>>jobs/pon/${sample}_pon_3.pbs
echo 'echo generating PON vcf took $ponT seconds'>>jobs/pon/${sample}_pon_3.pbs
