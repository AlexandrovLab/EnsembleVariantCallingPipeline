#!/bin/bash
email=$1
sample=$2
tumor=$3
normal=$4
ref=$5
fastq_path=$6
output=$7
USAGE="align_template.sh: not enough inputs...check script/n"
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
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V 
"

Tjobname="#PBS -N EVC_Talign_${sample}
#PBS -o ${sample}_Talign.o
#PBS -e ${sample}_Talign.e
"
Njobname="#PBS -N EVC_Nalign_${sample}
#PBS -o ${sample}_Nalign.o
#PBS -e ${sample}_Nalign.e
"
alignTumor="bwa mem -T 0 -t \$(nproc) -R '@RG\tID:${sample}\tSM:${sample}_tumor\tPL:ILLUMINA' $ref ${tumor_r1} ${tumor_r2} | samtools view -bh --input-fmt-option nthreads=\$(nproc) | samtools sort -@ \$(nproc) -m 6G>${sample}_tumor_raw.bam"
alignNormal="bwa mem -T 0 -t \$(nproc) -R '@RG\tID:${sample}\tSM:${sample}_normal\tPL:ILLUMINA' $ref ${normal_r1} ${normal_r2} | samtools view -bh --input-fmt-option nthreads=\$(nproc) | samtools sort -@ \$(nproc) -m 6G>${sample}_normal_raw.bam"

mkdpTumor="picard MarkDuplicates ASSUME_SORT_ORDER=coordinate CREATE_INDEX=true -XX:ParallelGCThreads=\$(nproc) -Xmx\$(free -h|grep Mem|awk '{print \$4}') VALIDATION_STRINGENCY=STRICT I=${sample}_tumor_raw.bam O=${sample}_tumor_mkdp.bam M=${sample}_tumor_markDuplicates_Matrix.txt"
mkdpNormal="picard MarkDuplicates ASSUME_SORT_ORDER=coordinate CREATE_INDEX=true -XX:ParallelGCThreads=\$(nproc) -Xmx\$(free -h|grep Mem|awk '{print \$4}') VALIDATION_STRINGENCY=STRICT I=${sample}_normal_raw.bam O=${sample}_normal_mkdp.bam M=${sample}_normal_markDuplicates_Matrix.txt"

printf "$header">jobs/align/${sample}_Talign.pbs
printf "${Tjobname}">>jobs/align/${sample}_Talign.pbs
printf "$header">jobs/align/${sample}_Nalign.pbs
printf "${Njobname}">>jobs/align/${sample}_Nalign.pbs
echo source ~/.bashrc>>jobs/align/${sample}_Talign.pbs
echo source ~/.bashrc>>jobs/align/${sample}_Nalign.pbs
echo source activate evc_main>>jobs/align/${sample}_Talign.pbs
echo source activate evc_main>>jobs/align/${sample}_Nalign.pbs


echo 'echo job starts at $(date)'>>jobs/align/${sample}_Talign.pbs
echo 'echo job starts at $(date)'>>jobs/align/${sample}_Nalign.pbs

echo cd $output>>jobs/align/${sample}_Talign.pbs
echo cd $output>>jobs/align/${sample}_Nalign.pbs
echo mkdir -p ${sample}>>jobs/align/${sample}_Talign.pbs
echo mkdir -p ${sample}>>jobs/align/${sample}_Nalign.pbs
echo cd ${sample}>>jobs/align/${sample}_Talign.pbs
echo cd ${sample}>>jobs/align/${sample}_Nalign.pbs

### bwa alignemnt ###
echo 'echo starting aligning tumor at $(date)'>>jobs/align/${sample}_Talign.pbs
echo 'echo starting aligning normal at $(date)'>>jobs/align/${sample}_Nalign.pbs
echo 'alignS=$SECONDS'>>jobs/align/${sample}_Talign.pbs
echo 'alignS=$SECONDS'>>jobs/align/${sample}_Nalign.pbs
echo $alignTumor>>jobs/align/${sample}_Talign.pbs
echo $alignNormal>>jobs/align/${sample}_Nalign.pbs
echo 'alignT=$(($SECONDS - $alignS))'>>jobs/align/${sample}_Talign.pbs
echo 'alignT=$(($SECONDS - $alignS))'>>jobs/align/${sample}_Nalign.pbs
echo "echo alignment took \$(echo a|awk '{print '\"\$alignT\"'/3600}') hours">>jobs/align/${sample}_Talign.pbs
echo "echo alignment took \$(echo a|awk '{print '\"\$alignT\"'/3600}') hours">>jobs/align/${sample}_Nalign.pbs

### MarkDuplicates ###
echo 'echo starting markDuplicates tumor at $(date)'>>jobs/align/${sample}_Talign.pbs
echo 'echo starting markDuplicates normal at $(date)'>>jobs/align/${sample}_Nalign.pbs
echo 'mkdpS=$SECONDS'>>jobs/align/${sample}_Talign.pbs
echo 'mkdpS=$SECONDS'>>jobs/align/${sample}_Nalign.pbs
echo $mkdpTumor>>jobs/align/${sample}_Talign.pbs
echo $mkdpNormal>>jobs/align/${sample}_Nalign.pbs
echo 'mkdpT=$(($SECONDS - $mkdpS))'>>jobs/align/${sample}_Talign.pbs
echo 'mkdpT=$(($SECONDS - $mkdpS))'>>jobs/align/${sample}_Nalign.pbs
echo "echo markduplicate took \$(echo a|awk '{print '\"\$mkdpT\"'/3600}') hours">>jobs/align/${sample}_Talign.pbs
echo "echo markduplicate took \$(echo a|awk '{print '\"\$mkdpT\"'/3600}') hours">>jobs/align/${sample}_Nalign.pbs


echo 'echo job ends at $(date)'>>jobs/align/${sample}_Talign.pbs
echo 'echo job ends at $(date)'>>jobs/align/${sample}_Nalign.pbs

fi
