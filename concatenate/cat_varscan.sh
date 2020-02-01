#!/bin/bash

precancer=$1
email=$2
listofsampleID=$3
list=$(echo "$listofsampleID" | cut -d '.' -f1)

USAGE="\nMissing input arguments..\n
must run under varscan job folder\n
USAGE:\cat_varscan.sh \\
	precancer type \\
	email.for@notification \\
	optional: listofsampleID.txt(jobname would end with the filename of this list)\n\n"

if [ -z "$2" ]
then
	printf "$USAGE"
	exit 1
fi

header="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M $email
#PBS -V 
#PBS -N ${precancer}_varscan
#PBS -o ${precancer}_varscan.o
#PBS -e ${precancer}_varscan.e
"
header_list="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M $email
#PBS -V 
#PBS -N ${precancer}_varscan_${list}
#PBS -o ${precancer}_varscan_${list}.o
#PBS -e ${precancer}_varscan_${list}.e
"

if [ -z "$3" ]
then
	printf "$header" > ${precancer}_varscan.pbs
	echo source ~/.bashrc >> ${precancer}_varscan.pbs
	echo source activate evc_main >> ${precancer}_varscan.pbs
	for file in PCGA*varscan.pbs; do sed '1,12d' $file >> ${precancer}_varscan.pbs;done
else
	printf "$header_list" > ${precancer}_varscan_${list}.pbs
	echo source ~/.bashrc >> ${precancer}_varscan_${list}.pbs
	echo source activate evc_main >> ${precancer}_varscan_${list}.pbs
	cat $listofsampleID | while read line; do sed '1,12d' ${line}_varscan.pbs >> ${precancer}_varscan_${list}.pbs;done
fi
