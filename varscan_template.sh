#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4
walltime=$5
queue=$6
normal=${out}/${sample}/${sample}_normal_final.bam
tumor=${out}/${sample}/${sample}_tumor_final.bam
mpileup=${out}/${sample}/mpileup/${sample}.mpileup
varscanOutput=${out}/${sample}/varscan



mpileup_nt_cmd="samtools mpileup --input-fmt-option nthreads=\$(nproc) -f $ref -q 1 -B $normal $tumor > $mpileup"
varscan_vcf_cmd="varscan somatic $mpileup ${varscanOutput}/${sample} --mpileup 1 --output-vcf --tumor-purity \${vs_tumor_purity}"
varscan_filter_snp_cmd="varscan somaticFilter ${varscanOutput}/${sample}.snp.vcf --min-coverage \${vs_min_converage} --min-reads2 \${vs_min_alt_reads} --min-var-freq \${vs_min_aaf}"
varscan_filter_indel_cmd="varscan somaticFilter ${varscanOutput}/${sample}.indel.vcf --min-coverage \${vs_min_converage} --min-reads2 \${vs_min_alt_reads} --min-var-freq \${vs_min_aaf}"
varscan_processSomatic_snp_cmd="varscan processSomatic ${varscanOutput}/${sample}.snp.vcf"
varscan_processSomatic_indel_cmd="varscan processSomatic ${varscanOutput}/${sample}.indel.vcf"


if [ ${queue} == "hotel" ]
then
	header="#!/bin/bash
#PBS -q hotel
#PBS -l nodes=1:ppn=8
#PBS -l walltime=${walltime}:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_varscan_${sample}
#PBS -e ${sample}_varscan.e
#PBS -o ${sample}_varscan.o


#VarScan parameters
vs_tumor_purity=0.8
vs_min_converage=10
vs_min_alt_reads=3
vs_min_aaf=0.2


source ~/.bashrc
source activate evc_main
mkdir -p ${out}/${sample}/varscan
mkdir -p ${out}/${sample}/mpileup
cd ${out}/${sample}/varscan
"
else
	header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=${walltime}:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V 
  #PBS -N EVC_varscan_${sample}
#PBS -e ${sample}_varscan.e
#PBS -o ${sample}_varscan.o


#VarScan parameters
vs_tumor_purity=0.8
vs_min_converage=10
vs_min_alt_reads=3
vs_min_aaf=0.2


source ~/.bashrc
source activate evc_main
mkdir -p ${out}/${sample}/varscan
mkdir -p ${out}/${sample}/mpileup
cd ${out}/${sample}/varscan
"
fi

printf "$header">jobs/varscan/${sample}_varscan.pbs

echo 'echo === Starting varscan on sample' ${sample} 'at $(date)==='>>jobs/varscan/${sample}_varscan.pbs
echo 'echo starting mpileup at $(date)....'>>jobs/varscan/${sample}_varscan.pbs
echo 'mpileupS=$SECONDS'>>jobs/varscan/${sample}_varscan.pbs
echo ${mpileup_nt_cmd}>>jobs/varscan/${sample}_varscan.pbs
echo 'mpileupT=$(($SECONDS-$mpileupS))'>>jobs/varscan/${sample}_varscan.pbs
echo "echo mpileup took \$(echo a|awk '{print '\"\$mpileupT\"'/3600}') hours">>jobs/varscan/${sample}_varscan.pbs

echo 'echo starting varscan vcf at $(date)....'>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanvcfS=$SECONDS'>>jobs/varscan/${sample}_varscan.pbs
echo ${varscan_vcf_cmd}>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanvcfT=$(($SECONDS - $varscanvcfS))'>>jobs/varscan/${sample}_varscan.pbs
echo "echo varscan took \$(echo a|awk '{print '\"\$varscanvcfT\"'/3600}') hours">>jobs/varscan/${sample}_varscan.pbs

echo 'echo starting varscan SNP filtering at $(date)....'>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanSNPfilterS=$SECONDS'>>jobs/varscan/${sample}_varscan.pbs
echo ${varscan_filter_snp_cmd}>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanSNPfilterT=$(($SECONDS - $varscanSNPfilterS))'>>jobs/varscan/${sample}_varscan.pbs
echo 'echo SNP filteriing took $varscanSNPfilterT seconds'>>jobs/varscan/${sample}_varscan.pbs

echo 'echo starting varscan INDEL filteriing at $(date)....'>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanINDELfilterS=$SECONDS'>>jobs/varscan/${sample}_varscan.pbs
echo ${varscan_filter_indel_cmd}>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanINDELfilterT=$(($SECONDS - $varscanINDELfilterS))'>>jobs/varscan/${sample}_varscan.pbs
echo 'echo INDEL filteriing took $varscanINDELfilterT seconds'>>jobs/varscan/${sample}_varscan.pbs

echo 'echo starting varscan SNP processSomatic at $(date)....'>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanSNPprocessSomaticS=$SECONDS'>>jobs/varscan/${sample}_varscan.pbs
echo ${varscan_processSomatic_snp_cmd}>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanSNPprocessSomaticT=$(($SECONDS - $varscanSNPprocessSomaticS))'>>jobs/varscan/${sample}_varscan.pbs
echo 'echo SNP processSomatic took $varscanSNPprocessSomaticT seconds'>>jobs/varscan/${sample}_varscan.pbs

echo 'echo starting varscan INDEL processSomatic at $(date)....'>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanINDELprocessSomaticS=$SECONDS'>>jobs/varscan/${sample}_varscan.pbs
echo ${varscan_processSomatic_indel_cmd}>>jobs/varscan/${sample}_varscan.pbs
echo 'varscanINDELprocessSomaticT=$(($SECONDS - $varscanINDELprocessSomaticS))'>>jobs/varscan/${sample}_varscan.pbs
echo 'echo INDEL processSomatic took $varscanINDELprocessSomaticT seconds'>>jobs/varscan/${sample}_varscan.pbs
echo 'echo job finished at $(date)'>>jobs/varscan/${sample}_varscan.pbs
