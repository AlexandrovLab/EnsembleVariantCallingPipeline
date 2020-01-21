#!/bin/bash

precancer=$1
email=$2

USAGE="\nMissing input arguments..\n
must run under align job folder\n
USAGE:\cat_align.sh \\
	precancer type \\
	email.for@notification \n\n"

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

printf "$header" > ${precancer}_align.pbs
echo source ~/.bashrc >> ${precancer}_align.pbs
echo source activate evc_main >> ${precancer}_align.pbs
for file in PCGA*align.pbs; do sed '1,12d' $file >> ${precancer}_align.pbs;done


