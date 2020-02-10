#!/bin/bash

precancer=$1
email=$2
listofsampleID=$3
list=$(echo "$listofsampleID" | cut -d '.' -f1)

USAGE="\nMissing input arguments..\n
must run under mutect job folder\n
USAGE:\cat_mutect.sh \\
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
#PBS -N ${precancer}_mutect
#PBS -o ${precancer}_mutect.o
#PBS -e ${precancer}_mutect.e
"
header_list="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M $email
#PBS -V 
#PBS -N ${precancer}_mutect_${list}
#PBS -o ${precancer}_mutect_${list}.o
#PBS -e ${precancer}_mutect_${list}.e
"

if [ -z "$3" ]
then
	printf "$header" > ${precancer}_mutect.pbs
	echo source ~/.bashrc >> ${precancer}_mutect.pbs
	echo source activate evc_main >> ${precancer}_mutect.pbs
	for file in PCGA*mutect.pbs; do sed '1,13d' $file >> ${precancer}_mutect.pbs;done
else
	printf "$header_list" > ${precancer}_mutect_${list}.pbs
	echo source ~/.bashrc >> ${precancer}_mutect_${list}.pbs
	echo source activate evc_main >> ${precancer}_mutect_${list}.pbs
	cat $listofsampleID | while read line; do sed '1,13d' ${line}_mutect.pbs >> ${precancer}_mutect_${list}.pbs;done
fi
