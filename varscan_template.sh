#!/bin/bash
email=$1
sample=$2
ref=$3
out=$4

normal=${out}/${sample}/${sample}_normal_final.bam
tumor=${out}/${sample}/${sample}_tumor_final.bam
mpileup=${out}/${sample}/mpileup/${sample}.mpileup
varscanOutput=${out}/${sample}/varscan



mpileup_nt_cmd="samtools mpileup --input-fmt-option nthreads=$(nproc) -f $ref -q 1 -B $normal $tumor > $mpileup"
varscan_vcf_cmd="varscan somatic $mpileup ${varscanOutput}/${sample} --mpileup 1 --output-vcf --tumor-purity vs_tumor_purity"
varscan_filter_snp_cmd="varscan somaticFilter ${varscanOutput}/${sample}.snp.vcf --min-coverage $vs_min_converage --min-reads2 $vs_min_alt_reads --min-var-freq $vs_min_aaf"
varscan_filter_indel_cmd="varscan somaticFilter ${varscanOutput}/${sample}.indel.vcf --min-coverage $vs_min_converage --min-reads2 $vs_min_alt_reads --min-var-freq $vs_min_aaf"
varscan_processSomatic_snp_cmd="varscan processSomatic ${varscanOutput}/${sample}.snp.vcf"
varscan_processSomatic_indel_cmd="varscan processSomatic ${varscanOutput}/${sample}.indel.vcf"


template="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=150:00:00
#PBS -m bea
#PBS -M ${email}
#PBS -V
#PBS -N EVC_varscan_${sample}
#PBS -e ${sample}_varscan.e
#PBS -o ${sample}_varscan.o
"
: <<'END
#VarScan parameters
vs_tumor_purity = 0.8 #80% purity (tumor content)
vs_min_converage = 10
vs_min_alt_reads = 3
vs_min_aaf = 0.2
\n
source ~/.bashrc
source activate cvc_py3
mkdir -p ${out}/${sample}/varscan
mkdir -p ${out}/${sample}/mpileup
cd ${out}/${sample}/varscan
\n
echo starting mpileup....
mpileupS=$SECONDS
${mpileup_nt_cmd}
mpileupT=$(($SECONDS - $mpileupS))
echo mpileup took $mpileupT seconds
\n
echo starting varscan vcf....
varscanvcfS=$SECONDS
${varscan_vcf_cmd}
varscanvcfT=$(($SECONDS - $varscanvcfS))
echo varscan VCF took $varscanvcfT seconds
\n
echo starting varscan SNP filtering....
varscanSNPfilterS=$SECONDS
${varscan_filter_snp_cmd}
varscanSNPfilterT=$(($SECONDS - $varscanSNPfilterS))
echo SNP filteriing took $varscanSNPfilterT seconds
\n
echo starting varscan INDEL filteriing....
varscanINDELfilterS=$SECONDS
${varscan_filter_indel_cmd}
varscanINDELfilterT=$(($SECONDS - $varscanINDELfilterS))
echo INDEL filteriing took $varscanINDELfilterT seconds
\n
echo starting varscan SNP processSomatic....
varscanSNPprocessSomaticS=$SECONDS
${varscan_processSomatic_snp_cmd}
varscanSNPprocessSomaticT=$(($SECONDS - $varscanSNPprocessSomaticS))
echo SNP processSomatic took $varscanSNPprocessSomaticT seconds
\n
echo starting varscan INDEL processSomatic....
varscanINDELprocessSomaticS=$SECONDS
${varscan_processSomatic_indel_cmd}
varscanINDELprocessSomaticT=$(($SECONDS - $varscanINDELprocessSomaticS))
echo INDEL processSomatic took $varscanINDELprocessSomaticT seconds
\n"
#echo job finished at $(date)
END
printf "$template">jobs/varscan/${sample}_varscan.pbs

