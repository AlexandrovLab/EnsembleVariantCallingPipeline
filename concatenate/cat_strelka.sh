#!/bin/bash

precancer=$1
email=$2
listofsampleID=$3
list=$(echo "$listofsampleID" | cut -d '.' -f1)

USAGE="\nMissing input arguments..\n
must run under strelka job folder\n
USAGE:\cat_strelka.sh \\
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
#PBS -N ${precancer}_strelka
#PBS -o ${precancer}_strelka.o
#PBS -e ${precancer}_strelka.e
"
header_list="#!/bin/bash
#PBS -q home-alexandrov
#PBS -l nodes=1:ppn=28:skylake
#PBS -l walltime=500:00:00
#PBS -m bea
#PBS -M $email
#PBS -V 
#PBS -N ${precancer}_strelka_${list}
#PBS -o ${precancer}_strelka_${list}.o
#PBS -e ${precancer}_strelka_${list}.e
"

if [ -z "$3" ]
then
	printf "$header" > ${precancer}_strelka.pbs
	echo source ~/.bashrc >> ${precancer}_strelka.pbs
	echo source activate evc_strelka >> ${precancer}_strelka.pbs
	for file in PCGA*strelka.pbs; do sed '1,12d' $file >> ${precancer}_strelka.pbs;done
else
	printf "$header_list" > ${precancer}_strelka_${list}.pbs
	echo source ~/.bashrc >> ${precancer}_strelka_${list}.pbs
	echo source activate evc_strelka >> ${precancer}_strelka_${list}.pbs
	cat $listofsampleID | while read line; do sed '1,12d' ${line}_strelka.pbs >> ${precancer}_strelka_${list}.pbs;done
fi
