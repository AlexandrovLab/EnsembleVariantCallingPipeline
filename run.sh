#!/bin/bash
email=phoebehe@eng.ucsd.edu
ref=/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa
path=$1
out=$2
sampleF=$3
knownIndels=/restricted/alexandrov-group/shared/Reference_Genomes/known_indels/resources_broad_hg38_v0_Homo_sapiens_assembly38.known_indels.vcf
#dbSNP=
USAGE="\nMissing input arguments..\n
USAGE:\trun.sh \\
	path/to/project \\
	output/directory \\
	path/to/sample.txt \\
	\n\n"
if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]
then printf "$USAGE"
else
cd $out
mkdir -p jobs/align
mkdir -p jobs/refine
cat $sampleF|tail -n+2|while read line;do
sample=$(echo $line|cut -d ' ' -f1)
tumor=$(echo $line|cut -d ' ' -f2)
normal=$(echo $line|cut -d ' ' -f3)
./align_template.sh $email $sample $tumor $normal $ref $path $out
./coclean_template.sh $email $sample $ref $knownIndels $out; done
#for f in jobs/*align*.pbs;do qsub $f;done
fi