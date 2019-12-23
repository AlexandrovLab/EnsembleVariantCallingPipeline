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


while read ki;
do
IR_t=$(echo "${IR_t} -known $ki")
IR_n=$(echo "${IR_n} -known $ki")
done < <(cat ${known_indels})

while read br;
do
BR_t=$(echo "${BR_t} --knownSites $br")
BR_n=$(echo "${BR_n} --knownSites $br")
done < <(cat ${base_recalibration})


header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=300:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
"
Tjobname="#PBS -N EVC_Trefine_${sample}
#PBS -e ${sample}_Trefine.e
#PBS -o ${sample}_Trefine.o
"
Njobname="#PBS -N EVC_Nrefine_${sample}
#PBS -e ${sample}_Nrefine.e
#PBS -o ${sample}_Nrefine.o
"
PR_t="gatk3 -T PrintReads -R $ref -I ${sample}_tumor_idra.bam --BQSR ${sample}_tumor_bqsr.grp -o ${sample}_tumor_final.bam -Xmx20G"
PR_n="gatk3 -T PrintReads -R $ref -I ${sample}_normal_idra.bam --BQSR ${sample}_normal_bqsr.grp -o ${sample}_normal_final.bam -Xmx20G"

printf "$header">jobs/refine/${sample}_Trefine.pbs
printf "${Tjobname}">>jobs/refine/${sample}_Trefine.pbs
printf "$header">jobs/refine/${sample}_Nrefine.pbs
printf "${Njobname}">>jobs/refine/${sample}_Nrefine.pbs
echo source ~/.bashrc>>jobs/refine/${sample}_Trefine.pbs
echo source activate evc_gatk3>>jobs/refine/${sample}_Trefine.pbs
echo source ~/.bashrc>>jobs/refine/${sample}_Nrefine.pbs
echo source activate evc_gatk3>>jobs/refine/${sample}_Nrefine.pbs
echo cd ${out}/${sample}/>>jobs/refine/${sample}_Trefine.pbs
echo cd ${out}/${sample}/>>jobs/refine/${sample}_Nrefine.pbs


echo 'echo starting IndelRealigner at $(date)'>>jobs/refine/${sample}_Trefine.pbs
echo 'echo starting IndelRealigner at $(date)'>>jobs/refine/${sample}_Nrefine.pbs
echo 'idraS=$SECONDS'>>jobs/refine/${sample}_Trefine.pbs
echo 'idraS=$SECONDS'>>jobs/refine/${sample}_Nrefine.pbs
echo ${IR_t}>>jobs/refine/${sample}_Trefine.pbs
echo ${IR_n}>>jobs/refine/${sample}_Nrefine.pbs
echo 'idraT=$(($SECONDS - $idraS))'>>jobs/refine/${sample}_Trefine.pbs
echo 'idraT=$(($SECONDS - $idraS))'>>jobs/refine/${sample}_Nrefine.pbs
echo "echo Indel Realignemnt took \$(echo a|awk '{print '\"\$idraT\"'/3600}') hours">>jobs/refine/${sample}_Trefine.pbs
echo "echo Indel Realignemnt took \$(echo a|awk '{print '\"\$idraT\"'/3600}') hours">>jobs/refine/${sample}_Nrefine.pbs


echo 'echo starting BaseRecalibrator at $(date)'>>jobs/refine/${sample}_Trefine.pbs
echo 'echo starting BaseRecalibrator at $(date)'>>jobs/refine/${sample}_Nrefine.pbs
echo 'barcS=$SECONDS'>>jobs/refine/${sample}_Trefine.pbs
echo 'barcS=$SECONDS'>>jobs/refine/${sample}_Nrefine.pbs
echo ${BR_t}>>jobs/refine/${sample}_Trefine.pbs
echo ${BR_n}>>jobs/refine/${sample}_Nrefine.pbs
echo 'barcT=$(($SECONDS - $barcS))'>>jobs/refine/${sample}_Trefine.pbs
echo 'barcT=$(($SECONDS - $barcS))'>>jobs/refine/${sample}_Nrefine.pbs
echo "echo Base Recalibration took \$(echo a|awk '{print '\"\$barcT\"'/3600}') hours">>jobs/refine/${sample}_Trefine.pbs
echo "echo Base Recalibration took \$(echo a|awk '{print '\"\$barcT\"'/3600}') hours">>jobs/refine/${sample}_Nrefine.pbs


echo 'echo starting PrintReads at $(date)'>>jobs/refine/${sample}_Trefine.pbs
echo 'echo starting PrintReads at $(date)'>>jobs/refine/${sample}_Nrefine.pbs
echo 'prS=$SECONDS'>>jobs/refine/${sample}_Trefine.pbs
echo 'prS=$SECONDS'>>jobs/refine/${sample}_Nrefine.pbs
echo ${PR_t}>>jobs/refine/${sample}_Trefine.pbs
echo ${PR_n}>>jobs/refine/${sample}_Nrefine.pbs
echo 'prT=$(($SECONDS - $prS))'>>jobs/refine/${sample}_Trefine.pbs
echo 'prT=$(($SECONDS - $prS))'>>jobs/refine/${sample}_Nrefine.pbs
echo "echo Printing Reads took \$(echo a|awk '{print '\"\$prT\"'/3600}') hours">>jobs/refine/${sample}_Trefine.pbs
echo "echo Printing Reads took \$(echo a|awk '{print '\"\$prT\"'/3600}') hours">>jobs/refine/${sample}_Nrefine.pbs
echo 'echo Refinement finished at $(date)'>>jobs/refine/${sample}_Trefine.pbs
echo 'echo Refinement finished at $(date)'>>jobs/refine/${sample}_Nrefine.pbs


echo cd ${out}/jobs/pon/>>jobs/refine/${sample}_Nrefine.pbs
echo qsub ${sample}_pon.pbs>>jobs/refine/${sample}_Nrefine.pbs


tail="
if [ -f "${sample}_normal_final.bam" ] && [  -f "${sample}_tumor_final.bam" ]
then
cd ${out}/jobs/varscan
qsub ${sample}_varscan.pbs
cd ${out}/jobs/strelka
qsub ${sample}_strelka.pbs
else
echo 'job finished, waiting for the pair sample to finish for subsequent analysis'
fi
"
#printf "$tail">>jobs/refine/${sample}_Trefine.pbs
#printf "$tail">>jobs/refine/${sample}_Nrefine.pbs
