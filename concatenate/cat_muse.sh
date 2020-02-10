#!/bin/bash

precancer=$1
email=$2
listofsampleID=$3
list=$(echo "$listofsampleID" | cut -d '.' -f1)

USAGE="\nMissing input arguments..\n
must run under muse job folder\n
USAGE:\cat_muse.sh \\
	precancer type \\
	email.for@notification \\
	optional: listofsampleID.txt\n\n"

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
#PBS -N ${precancer}_muse
#PBS -o ${precancer}_muse.o
#PBS -e ${precancer}_muse.e
"
header_list="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M $email
#PBS -V 
#PBS -N ${precancer}_muse_${list}
#PBS -o ${precancer}_muse_${list}.o
#PBS -e ${precancer}_muse_${list}.e
"


if [ "$1" != "" ] && [ "$2" != "" ] && [ -z "$3" ]
then
	printf "$header" > ${precancer}_muse.pbs
	echo source ~/.bashrc >> ${precancer}_muse.pbs
	echo source activate evc_muse >> ${precancer}_muse.pbs
	for file in PCGA*muse.pbs; do sed '1,12d' $file >> ${precancer}_muse.pbs;done
fi

if [ "$1" != "" ] && [ "$2" != "" ] && [ "$3" != "" ]
then
	printf "$header_list" > ${precancer}_muse_${list}.pbs
	echo source ~/.bashrc >> ${precancer}_muse_${list}.pbs
	echo source activate evc_muse >> ${precancer}_muse_${list}.pbs
	cat $listofsampleID | while read line; do sed '1,12d' ${line}_muse.pbs >> ${precancer}_muse_${list}.pbs;done
fi



