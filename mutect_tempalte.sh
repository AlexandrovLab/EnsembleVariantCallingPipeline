#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
#type=$5
normal=${out}/${sample}/${sample}_normal_final.bam
tumor=${out}/${sample}/${sample}_tumor_final.bam
header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_mutect_${sample}
#PBS -e ${sample}_mutect.e
#PBS -o ${sample}_mutect.o
"
