#!/bin/bash

precancer=$1
email=$2
listofsampleID=$3
list=$(echo "$listofsampleID" | cut -d '.' -f1)

USAGE="\nMissing input arguments..\n
must run under pon job folder\n
USAGE:\cat_pon.sh \\
	precancer type \\
	email.for@notification \\
	optional: listofsampleID.txt(jobname would end with the filename of this list)\n\n"

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
#PBS -N ${precancer}_pon
#PBS -o ${precancer}_pon.o
#PBS -e ${precancer}_pon.e
"
header_list="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M $email
#PBS -V 
#PBS -N ${precancer}_pon_${list}
#PBS -o ${precancer}_pon_${list}.o
#PBS -e ${precancer}_pon_${list}.e
"


if [ "$1" != "" ] && [ "$2" != "" ] && [ -z "$3" ]
then
	printf "$header" > ${precancer}_pon.pbs
	echo source ~/.bashrc >> ${precancer}_pon.pbs
	echo source activate evc_main >> ${precancer}_pon.pbs
	for file in PCGA*pon.pbs; do sed '1,12d' $file >> ${precancer}_pon.pbs;done
fi

if [ "$1" != "" ] && [ "$2" != "" ] && [ "$3" != "" ]
then
	printf "$header_list" > ${precancer}_pon_${list}.pbs
	echo source ~/.bashrc >> ${precancer}_pon_${list}.pbs
	echo source activate evc_main >> ${precancer}_pon_${list}.pbs
	cat $listofsampleID | while read line; do sed '1,12d' ${line}_pon.pbs >> ${precancer}_pon_${list}.pbs;done
fi
