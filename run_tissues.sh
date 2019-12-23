#!/bin/bash

tissues_txt=$1
USAGE="USAGE: Run this after create_directories.sh

		run_tissues.sh \\
		txt_of_tissues_to_run \\
		new_analysis_path"


if [ -z "$1" ] || [ -z "$2" ]
then
	printf "$USAGE"
	exit 1
fi

for tissue in $(cat $tissues_txt)
do
	cd /restricted/alexandrov-group/shared/precancer_analysis/new_analysis/${tissue}/jobs/align
	for sample in $(tail -n+2 /restricted/alexandrov-group/shared/precancer_analysis/new_analysis/${tissue}/${tissue}.map | cut -f1)
	do
		qsub ${sample}_Nalign_1.pbs
		qsub ${sample}_Talign_1.pbs
	done
done