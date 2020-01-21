#!/bin/bash

precancer=$1
email=$2
listofsampleID=$3

USAGE="\nMissing input arguments..\n
must run under postAlign job folder\n
USAGE:\cat_postalign.sh \\
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
#PBS -N ${precancer}_postAlign
#PBS -o ${precancer}_postAlign.o
#PBS -e ${precancer}_postAlign.e
"
header_list="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M $email
#PBS -V 
#PBS -N ${precancer}_postAlign_list
#PBS -o ${precancer}_postAlign_list.o
#PBS -e ${precancer}_postAlign_list.e
"


if [ "$1" != "" ] && [ "$2" != "" ] && [ -z "$3" ]
then
	printf "$header" > ${precancer}_postAlign.pbs
	for file in PCGA*postAlign.pbs; do sed '1,10d' $file >> ${precancer}_postAlign.pbs;done
fi

if [ "$1" != "" ] && [ "$2" != "" ] && [ "$3" != "" ]
then
	printf "$header_list" > ${precancer}_postAlign_wlist.pbs
	cat $listofsampleID | while read line; do sed '1,10d' ${line}_postAlign.pbs >> ${precancer}_postAlign_wlist.pbs;done
fi
