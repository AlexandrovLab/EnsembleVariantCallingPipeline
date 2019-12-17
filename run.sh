#!/bin/bash
email=phoebehe@eng.ucsd.edu
ref=/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa
path=/restricted/alexandrov-group/shared/precancer_analysis/tissue_types/oral/olivier_oral/paired_end
out=$1
knownIndels=/restricted/alexandrov-group/shared/Reference_Genomes/known_indels/resources_broad_hg38_v0_Homo_sapiens_assembly38.known_indels.vcf
USAGE="\nMissing input arguments..\n
USAGE:\trun.sh \\
	path/to/project\n\n"
if [ "$1" == "" ] 
then printf "$USAGE"
else
cd $out
mkdir -p jobs/align
mkdir -p jobs/refine
cat /restricted/alexandrov-group/shared/precancer_analysis/tissue_types/oral/olivier_oral/olivier_oral_sample.txt|tail -n+2|while read line;do
sample=$(echo $line|cut -d ' ' -f1)
tumor=$(echo $line|cut -d ' ' -f2)
normal=$(echo $line|cut -d ' ' -f3)
./align_template.sh $email $sample $tumor $normal $ref $path $out
./coclean_template.sh $email $sample $ref $knownIndels $out; done
#for f in jobs/*align*.pbs;do qsub $f;done
fi
