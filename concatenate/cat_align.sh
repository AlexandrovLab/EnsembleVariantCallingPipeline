#!/bin/bash

precancer=$1
email=$2
listofsampleID=$3
list=$(echo "$listofsampleID" | cut -d '.' -f1)

USAGE="\nMissing input arguments..\n
must run under align job folder\n
USAGE:\cat_align.sh \\
	precancer type \\
	email.for@notification \\
	optional: listofsampleID.txt (jobname would end with the filename of this list)\n\n"

if [ -z "$1" ] || [ -z "$2" ]
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
#PBS -N ${precancer}_align
#PBS -o ${precancer}_align.o
#PBS -e ${precancer}_align.e
"
header_list="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M $email
#PBS -V 
#PBS -N ${precancer}_align_${list}
#PBS -o ${precancer}_align_${list}.o
#PBS -e ${precancer}_align_${list}.e
"


if [ "$1" != "" ] && [ "$2" != "" ] && [ -z "$3" ]
then
	printf "$header" > ${precancer}_align.pbs
	echo source ~/.bashrc >> ${precancer}_align.pbs
	echo source activate evc_main >> ${precancer}_align.pbs
	for file in PCGA*align.pbs; do sed '1,12d' $file >> ${precancer}_align.pbs;done
fi

if [ "$1" != "" ] && [ "$2" != "" ] && [ "$3" != "" ]
then
	printf "$header_list" > ${precancer}_align_${list}.pbs
	echo source ~/.bashrc >> ${precancer}_align_${list}.pbs
	echo source activate evc_main >> ${precancer}_align_${list}.pbs
	cat $listofsampleID | while read line; do sed '1,12d' ${line}_Talign.pbs >> ${precancer}_align_${list}.pbs;sed '1,12d' ${line}_Nalign.pbs >> ${precancer}_align_${list}.pbs;
done
fi


