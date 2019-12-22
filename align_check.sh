#!/bin/bash

USAGE="USAGE:\talign_check.sh \\
		map_file \\
		full_path_to_project_directory\n\n"

map_file=$1
project_dir=$2
oneGB=1000000

if [ -z "$1" ] || [ -z "$2" ]
then
	printf "$USAGE"
	exit 1
fi

cd ${project_dir}
mkdir -p ${project_dir}/jobs/check
alignment_failed_samples=${project_dir}/jobs/check/alignment_fail.txt
printf "" > $alignment_failed_samples

for sample in $(tail -n+2 $map_file | cut -f1)
do
	#stop when there 
	tumor_errors=0
	normal_errors=0

	####################
	##Check error file##
	####################

	tumor_error_file=${project_dir}/jobs/align/${sample}_Talign_1.e
	normal_error_file=${project_dir}/jobs/align/${sample}_Nalign_1.e

	#if tumor failed
	if [ ! -z "$(grep -i error $tumor_error_file)" ] || [ ! -z "$(grep -i fail $tumor_error_file)" ]
	then
		printf "${sample}_tumor\n" >> $alignment_failed_samples
		(( tumor_errors ++ ))
	fi

	#if normal failed
	if [ ! -z "$(grep -i error $normal_error_file)" ] || [ ! -z "$(grep -i fail $normal_error_file)" ]
	then
		printf "${sample}_normal\n" >> $alignment_failed_samples
		(( normal_errors ++ ))
	fi


	###################
	##Check num files##
	###################
	
	bampath=${project_dir}/$sample
	tbam_raw=${bampath}/${sample}_tumor_raw.bam
	tbam_mkdup=${bampath}/${sample}_tumor_mkdp.bam
	nbam_raw=${bampath}/${sample}_normal_raw.bam
	nbam_mkdup=${bampath}/${sample}_normal_mkdp.bam

	#check if mkdp and raw files exist
	if [ ${tumor_errors} -lt 1 ] && ( [ ! -e $tbam_mkdup ] || [ ! -e $tbam_raw ] )
	then
		printf "${sample}_tumor\n" >> $alignment_failed_samples
		(( tumor_errors ++ ))
	fi

	if [ ${normal_errors} -lt 1 ] && ( [ ! -e $nbam_mkdup ] || [ ! -e $nbam_raw ] )
	then
		printf "${sample}_normal\n" >> $alignment_failed_samples
		(( normal_errors ++ ))
	fi


	####################
	##Check file sizes##
	####################

	#mkdup too small or either bam <1gb means error
	if [ ${tumor_errors} -lt 1 ]
	then
		tmkdup_size="$(du $tbam_mkdup | cut -f1)"
		traw_size="$(du $tbam_raw | cut -f1)"
		
		if [ ${tmkdup_size} -lt ${traw_size} ] || [ ${tmkdup_size} -lt $oneGB ] || [ ${traw_size} -lt $oneGB ]
		then
			printf "${sample}_tumor\n" >> $alignment_failed_samples
			(( tumor_errors ++ ))
		fi
	fi

	if [ ${normal_errors} -lt 1 ]
	then
		nmkdup_size="$(du $nbam_mkdup | cut -f1)"
		nraw_size="$(du $nbam_raw | cut -f1)"

		if [ ${nmkdup_size} -lt ${nraw_size} ] || [ ${nmkdup_size} -lt $oneGB ] || [ ${nraw_size} -lt $oneGB ]
		then
			printf "${sample}_normal\n" >> $alignment_failed_samples
			(( normal_errors ++ ))
		fi
	fi


	####################
	##Submit next step##
	####################

	if [ ${normal_errors} -lt 1 ] && [ ${tumor_errors} -lt 1 ]
	then
		echo qsub ${project_dir}/jobs/refine/${sample}_targetInterval.pbs
	fi	
done