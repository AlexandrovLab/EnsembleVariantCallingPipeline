#!/bin/bash

USAGE="USAGE:\trefine_check.sh \\
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
refine_failed_samples=${project_dir}/jobs/check_and_go/refine_$(date|awk '{OFS="-";$1=$1;print}').error
refine_next_script=${project_dir}/jobs/check_and_go/strelka_and_varscan.sh

printf "Check refine was performed at $(date)\n########### ERROR report ##########\n" > ${refine_failed_samples}
printf "#!/bin/bash
#Run this after refine is done\n\n" > ${refine_next_script}


for sample in $(tail -n+2 ${map_file} | cut -f1)
do
	#stop when there 
	tumor_errors=0
	normal_errors=0

	###################
	##Check num files##
	###################
	
	bampath=${project_dir}/$sample
	target_intervals=${bampath}/${sample}_realign_target.intervals

	tbam_mkdup=${bampath}/${sample}_tumor_mkdp.bam
	tbam_bqsr=${bampath}/${sample}_tumor_bqsr.grp
	tbam_final=${bampath}/${sample}_tumor_final.bam
	tbai_final=${bampath}/${sample}_tumor_final.bai
	tbam_indelra=${bampath}/${sample}_tumor_idra.bam
	tbai_indelra=${bampath}/${sample}_tumor_idra.bai

	nbam_mkdup=${bampath}/${sample}_normal_mkdp.bam
	nbam_bqsr=${bampath}/${sample}_normal_bqsr.grp
	nbam_final=${bampath}/${sample}_normal_final.bam
	nbai_final=${bampath}/${sample}_normal_final.bai
	nbam_indelra=${bampath}/${sample}_normal_idra.bam
	nbai_indelra=${bampath}/${sample}_normal_idra.bai


	#check if mkdp and raw files exist
	if [ ! -e ${tbam_bqsr} ] || [ ! -e ${tbam_final} ] || [ ! -e ${tbai_final} ] || [ ! -e ${tbam_indelra} ] || [ ! -e ${tbai_indelra} ] || [ ! -e ${target_intervals} ]
	then
		printf "${sample}_tumor\n" >> ${refine_failed_samples}
		(( tumor_errors ++ ))
	fi

	if [ ! -e ${nbam_bqsr} ] || [ ! -e ${nbam_final} ] || [ ! -e ${nbai_final} ] || [ ! -e ${nbam_indelra} ] || [ ! -e ${nbai_indelra} ] || [ ! -e ${target_intervals} ]
	then
		printf "${sample}_normal\n" >> ${refine_failed_samples}
		(( normal_errors ++ ))
	fi


	####################
	##Check file sizes##
	####################

	#mkdup too small or either bam <1gb means error
	if [ ${tumor_errors} -lt 1 ] && [ -e ${tbam_mkdup} ]
	then
		tmkdup_size="$(du ${tbam_mkdup} | cut -f1)"
		tfinal_size="$(du ${tbam_final} | cut -f1)"
		tidra_size="$(du ${tbam_indelra} | cut -f1)"
		
		if [ ${tmkdup_size} -gt ${tidra_size} ] || [ ${tfinal_size} -lt ${tidra_size} ] || [ ${tfinal_size} -lt $oneGB ] || [ ${tidra_size} -lt $oneGB ]
		then
			printf "${sample}_tumor\n" >> ${refine_failed_samples}
			(( tumor_errors ++ ))
		fi
	fi

	if [ ${normal_errors} -lt 1 ] && [ -e ${nbam_mkdup} ]
	then
		nmkdup_size="$(du ${nbam_mkdup} | cut -f1)"
		nfinal_size="$(du ${nbam_final} | cut -f1)"
		nidra_size="$(du ${nbam_indelra} | cut -f1)"

		if [ ${nmkdup_size} -gt ${nidra_size} ] || [ ${nfinal_size} -lt ${nidra_size} ] || [ ${nfinal_size} -lt $oneGB ] || [ ${nidra_size} -lt $oneGB ]
		then
			printf "${sample}_normal\n" >> ${refine_failed_samples}
			(( normal_errors ++ ))
		fi
	fi


	####################
	##Submit next step##
	####################

	if [ ${normal_errors} -lt 1 ] && [ ${tumor_errors} -lt 1 ]
	then
		echo cd ${project_dir}/jobs/varscan/ >> ${refine_next_script}
		echo qsub ${sample}_varscan.pbs >> ${refine_next_script} | awk -v samp=$sample -F"." '{print $1"\t"samp}'>>${project_dir}/jobs/check_and_go/varscan_job_IDs.txt

		echo cd ${project_dir}/jobs/strelka/ >> ${refine_next_script}
		echo qsub ${sample}_strelka.pbs >> ${refine_next_script} | awk -v samp=$sample -F"." '{print $1"\t"samp}'>>${project_dir}/jobs/check_and_go/strelka_job_IDs.txt

	fi	
done