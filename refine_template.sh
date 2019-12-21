#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
known_indels=$5
base_recalibration=$6


BR_t="gatk3 -T BaseRecalibrator -R $ref -I ${sample}_tumor_idra.bam -o ${sample}_tumor_bqsr.grp -Xmx20G"
BR_n="gatk3 -T BaseRecalibrator -R $ref -I ${sample}_normal_idra.bam -o ${sample}_normal_bqsr.grp -Xmx20G"


IR_t="gatk3 -T IndelRealigner -R $ref -targetIntervals ${sample}_realign_target.intervals --noOriginalAlignmentTags -I ${sample}_tumor_mkdp.bam -o ${sample}_tumor_idra.bam -Xmx20G"
IR_n="gatk3 -T IndelRealigner -R $ref -targetIntervals ${sample}_realign_target.intervals --noOriginalAlignmentTags -I ${sample}_normal_mkdp.bam -o ${sample}_normal_idra.bam -Xmx20G"


cat ${known_indels}|while read ki;
do
echo $ki
eval IR_t="${IR_t} -known $ki"
eval IR_n="${IR_n} -known $ki"
done

cat ${base_recalibration}|while read br;
do
echo $br
eval BR_t="${BR_t} --knownSites $br"
eval BR_n="${BR_n} --knownSites $br"
done


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
PR_t="gatk3 -T PrintReads -R $ref -I ${sample}_tumor_idra.bam --BQSR ${sample}_tumor_bqsr.grp -o ${sample}_tumor_final.bam -Xmx20G"
PR_n="gatk3 -T PrintReads -R $ref -I ${sample}_normal_idra.bam --BQSR ${sample}_normal_bqsr.grp -o ${sample}_normal_final.bam -Xmx20G"

printf "$header">jobs/refine/${sample}_Trefine_2.pbs
printf "${Tjobname}">>jobs/refine/${sample}_Trefine_2.pbs
printf "$header">jobs/refine/${sample}_Nrefine_2.pbs
printf "${Njobname}">>jobs/refine/${sample}_Nrefine_2.pbs
echo source ~/.bashrc>>jobs/refine/${sample}_Trefine_2.pbs
echo source activate evc_gatk3>>jobs/refine/${sample}_Trefine_2.pbs
echo source ~/.bashrc>>jobs/refine/${sample}_Nrefine_2.pbs
echo source activate evc_gatk3>>jobs/refine/${sample}_Nrefine_2.pbs
echo cd ${out}/${sample}/>>jobs/refine/${sample}_Trefine_2.pbs
echo cd ${out}/${sample}/>>jobs/refine/${sample}_Nrefine_2.pbs

echo 'echo starting IndelRealigner at $(date)'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo starting IndelRealigner at $(date)'>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'idraS=$SECONDS'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'idraS=$SECONDS'>>jobs/refine/${sample}_Nrefine_2.pbs
echo ${IR_t}>>jobs/refine/${sample}_Trefine_2.pbs
echo ${IR_n}>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'idraT=$(($SECONDS - $idraS))'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'idraT=$(($SECONDS - $idraS))'>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'echo indel alignemnt took $idraT seconds'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo indel alignemnt took $idraT seconds'>>jobs/refine/${sample}_Nrefine_2.pbs


echo 'echo starting BaseRecalibrator at $(date)'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo starting BaseRecalibrator at $(date)'>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'barcS=$SECONDS'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'barcS=$SECONDS'>>jobs/refine/${sample}_Nrefine_2.pbs
echo ${BR_t}>>jobs/refine/${sample}_Trefine_2.pbs
echo ${BR_n}>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'barcT=$(($SECONDS - $barcS))'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'barcT=$(($SECONDS - $barcS))'>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'echo Base Recalibration took $barcT seconds'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo Base Recalibration took $barcT seconds'>>jobs/refine/${sample}_Nrefine_2.pbs


echo 'echo starting PrintReads at $(date)'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo starting PrintReads at $(date)'>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'prS=$SECONDS'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'prS=$SECONDS'>>jobs/refine/${sample}_Nrefine_2.pbs
echo ${PR_t}>>jobs/refine/${sample}_Trefine_2.pbs
echo ${PR_n}>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'prT=$(($SECONDS - $prS))'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'prT=$(($SECONDS - $prS))'>>jobs/refine/${sample}_Nrefine_2.pbs
echo 'echo Printing Reads took $prT seconds'>>jobs/refine/${sample}_Trefine_2.pbs
echo 'echo Printing Reads took $prT seconds'>>jobs/refine/${sample}_Nrefine_2.pbs

