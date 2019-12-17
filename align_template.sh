#!/bin/bash
email=$1
sample=$2
tumor=$3
normal=$4
ref=$5
fastq_path=$6
output=$7
USAGE="not enough inputs...check script/n"
if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ] || [ "$5" == "" ] || [ "$6" == "" ] || [ "$7" == "" ]
then printf "$USAGE"
else
tumor_r1=${fastq_path}/${tumor}_1.fastq.gz
tumor_r2=${fastq_path}/${tumor}_2.fastq.gz
normal_r1=${fastq_path}/${normal}_1.fastq.gz
normal_r2=${fastq_path}/${normal}_2.fastq.gz

header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V 
"

Tjobname="#PBS -N EVC_align_${sample}_tumor
#PBS -o ${sample}_Talign_1.o
#PBS -e ${sample}_Talign_1.e
"
Njobname="#PBS -N EVC_align_${sample}_normal
#PBS -o ${sample}_Nalign_1.o
#PBS -e ${sample}_Nalign_1.e
"
alignTumor="bwa mem -T 0 -t \$(nproc) -R '@RG\tID:${sample}_tumor\tSM:${sample}_tumor\tPL:ILLUMINA' $ref ${tumor_r1} ${tumor_r2} | samtools view -bh --input-fmt-option nthreads=\$(nproc) | samtools sort -@ 14 -m 12G >${sample}_tumor_raw.bam"
alignNormal="bwa mem -T 0 -t \$(nproc) -R '@RG\tID:${sample}_normal\tSM:${sample}_normal\tPL:ILLUMINA' $ref ${normal_r1} ${normal_r2} | samtools view -bh --input-fmt-option nthreads=\$(nproc) | samtools sort -@ 14 -m 12G >${sample}_normal_raw.bam"

mkdpTumor="picard MarkDuplicates ASSUME_SORT_ORDER=coordinate CREATE_INDEX=true -XX:ParallelGCThreads=\$(nproc) -Xmx\$(free -h|grep Mem|awk '{print \$4}') VALIDATION_STRINGENCY=STRICT I=${sample}_tumor_raw.bam O=${sample}_tumor_mkdp.bam M=${sample}_tumor_markDuplicates_Matrix.txt"
mkdpNormal="picard MarkDuplicates ASSUME_SORT_ORDER=coordinate CREATE_INDEX=true -XX:ParallelGCThreads=\$(nproc) -Xmx\$(free -h|grep Mem|awk '{print \$4}') VALIDATION_STRINGENCY=STRICT I=${sample}_normal_raw.bam O=${sample}_normal_mkdp.bam M=${sample}_normal_markDuplicates_Matrix.txt"

printf "$header">jobs/align/${sample}_Talign_1.pbs
printf "${Tjobname}">>jobs/align/${sample}_Talign_1.pbs
printf "$header">jobs/align/${sample}_Nalign_1.pbs
printf "${Njobname}">>jobs/align/${sample}_Nalign_1.pbs
echo source ~/.bashrc>>jobs/align/${sample}_Talign_1.pbs
echo source ~/.bashrc>>jobs/align/${sample}_Nalign_1.pbs
echo source activate cvc_py3>>jobs/align/${sample}_Talign_1.pbs
echo source activate cvc_py3>>jobs/align/${sample}_Nalign_1.pbs
echo 'echo job starts at $(date)'>>jobs/align/${sample}_Talign_1.pbs
echo 'echo job starts at $(date)'>>jobs/align/${sample}_Nalign_1.pbs
echo cd $output>>jobs/align/${sample}_Talign_1.pbs
echo cd $output>>jobs/align/${sample}_Nalign_1.pbs
echo mkdir ${sample}_talign>>jobs/align/${sample}_Talign_1.pbs
echo mkdir ${sample}_nalign>>jobs/align/${sample}_Nalign_1.pbs
echo cd ${sample}_talign>>jobs/align/${sample}_Talign_1.pbs
echo cd ${sample}_nalign>>jobs/align/${sample}_Nalign_1.pbs
echo 'echo starting aligning tumor at $(date)'>>jobs/align/${sample}_Talign_1.pbs
echo 'alignS=$SECONDS'>>jobs/align/${sample}_Talign_1.pbs
echo 'alignS=$SECONDS'>>jobs/align/${sample}_Nalign_1.pbs
echo $alignTumor>>jobs/align/${sample}_Talign_1.pbs
echo 'echo starting aligning normal at $(date)'>>jobs/align/${sample}_Nalign_1.pbs
echo $alignNormal>>jobs/align/${sample}_Nalign_1.pbs
echo 'alignT=$(($SECONDS - $alignS))'>>jobs/align/${sample}_Talign_1.pbs
echo 'alignT=$(($SECONDS - $alignS))'>>jobs/align/${sample}_Nalign_1.pbs
echo 'echo alignment took $alignT seconds' >>jobs/align/${sample}_Talign_1.pbs
echo 'echo alignment took $alignT seconds'>>jobs/align/${sample}_Nalign_1.pbs
echo 'echo starting markDuplicates tumor at $(date)'>>jobs/align/${sample}_Talign_1.pbs
echo 'mkdpS=$SECONDS'>>jobs/align/${sample}_Talign_1.pbs
echo 'mkdpS=$SECONDS'>>jobs/align/${sample}_Nalign_1.pbs
echo $mkdpTumor>>jobs/align/${sample}_Talign_1.pbs
echo 'echo starting markDuplicates normal at $(date)'>>jobs/align/${sample}_Nalign_1.pbs
echo $mkdpNormal>>jobs/align/${sample}_Nalign_1.pbs
echo 'mkdpT=$(($SECONDS - $mkdpS))'>>jobs/align/${sample}_Talign_1.pbs
echo 'mkdpT=$(($SECONDS - $mkdpS))'>>jobs/align/${sample}_Nalign_1.pbs
echo 'echo markduplicate took $mkdpT seconds' >>jobs/align/${sample}_Talign_1.pbs
echo 'echo markduplicate took $mkdpT seconds'>>jobs/align/${sample}_Nalign_1.pbs
echo 'echo job ends at $(date)'>>jobs/align/${sample}_Talign_1.pbs
echo 'echo job ends at $(date)'>>jobs/align/${sample}_Nalign_1.pbs
fi
