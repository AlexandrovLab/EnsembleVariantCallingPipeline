#!/bin/bash


USAGE="USAGE:\trefine_check_template.sh \\
		map_file \\
		full_path_to_project_directory\n\n"

map_file=$1
project_dir=$2

printf "#!/bin/bash

oneGB=1000000

cd ${project_dir}

refine_failed_samples=${project_dir}/jobs/check_and_go/refine_\$(date|awk '{OFS=\"-\";\$1=\$1;print}').error
varscan_script=${project_dir}/jobs/check_and_go/varscan.sh
strelka_script=${project_dir}/jobs/check_and_go/strelka.sh
varscan_job_ID=${project_dir}/jobs/check_and_go/varscan_job_IDs.txt
strelka_job_ID=${project_dir}/jobs/check_and_go/strelka_job_IDs.txt

printf \"Check refine was performed at \$(date)
########### ERROR report ##########\\\n\" > \${refine_failed_samples}

printf \"#!/bin/bash
#Run this after refine is done\\\n
cd ${project_dir}/jobs/varscan/\\\n\\\n\" > \${varscan_script}

printf \"#!/bin/bash
#Run this after refine is done\\\n
cd ${project_dir}/jobs/strelka/\\\n\\\n\" > \${strelka_script}

printf \"\" > \${varscan_job_ID}
printf \"\" > \${strelka_job_ID}

chmod 770 \${refine_failed_samples} \${varscan_script} \${strelka_script} \${varscan_job_ID} \${strelka_job_ID}


for sample in \$(tail -n+2 ${map_file} | cut -f1)
do
	#stop when there 
	tumor_errors=0
	normal_errors=0

	###################
	##Check num files##
	###################
	
	bampath=${project_dir}/\$sample
	target_intervals=\${bampath}/\${sample}_realign_target.intervals

	tbam_mkdup=\${bampath}/\${sample}_tumor_mkdp.bam
	tbam_bqsr=\${bampath}/\${sample}_tumor_bqsr.grp
	tbam_final=\${bampath}/\${sample}_tumor_final.bam
	tbai_final=\${bampath}/\${sample}_tumor_final.bai
	tbam_indelra=\${bampath}/\${sample}_tumor_idra.bam
	tbai_indelra=\${bampath}/\${sample}_tumor_idra.bai

	nbam_mkdup=\${bampath}/\${sample}_normal_mkdp.bam
	nbam_bqsr=\${bampath}/\${sample}_normal_bqsr.grp
	nbam_final=\${bampath}/\${sample}_normal_final.bam
	nbai_final=\${bampath}/\${sample}_normal_final.bai
	nbam_indelra=\${bampath}/\${sample}_normal_idra.bam
	nbai_indelra=\${bampath}/\${sample}_normal_idra.bai


	#check if mkdp and raw files exist
	if [ ! -e \${tbam_bqsr} ] || [ ! -e \${tbam_final} ] || [ ! -e \${tbai_final} ] || [ ! -e \${tbam_indelra} ] || [ ! -e \${tbai_indelra} ] || [ ! -e \${target_intervals} ]
	then
		printf \"\${sample}_tumor\\\n\" >> \${refine_failed_samples}
		(( tumor_errors ++ ))
	fi

	if [ ! -e \${nbam_bqsr} ] || [ ! -e \${nbam_final} ] || [ ! -e \${nbai_final} ] || [ ! -e \${nbam_indelra} ] || [ ! -e \${nbai_indelra} ] || [ ! -e \${target_intervals} ]
	then
		printf \"\${sample}_normal\\\n\" >> \${refine_failed_samples}
		(( normal_errors ++ ))
	fi


	####################
	##Check file sizes##
	####################

	#mkdup too small or either bam <1gb means error
	if [ \${tumor_errors} -lt 1 ] && [ -e \${tbam_mkdup} ]
	then
		tmkdup_size=\"\$(du -b \${tbam_mkdup} | cut -f1)\"
		tfinal_size=\"\$(du -b \${tbam_final} | cut -f1)\"
		tidra_size=\"\$(du -b \${tbam_indelra} | cut -f1)\"
		
		if [ \${tmkdup_size} -gt \${tidra_size} ] || [ \${tfinal_size} -lt \${tidra_size} ] || [ \${tfinal_size} -lt \$oneGB ] || [ \${tidra_size} -lt \$oneGB ]
		then
			printf \"\${sample}_tumor\\\n\" >> \${refine_failed_samples}
			(( tumor_errors ++ ))
		fi
	fi

	if [ \${normal_errors} -lt 1 ] && [ -e \${nbam_mkdup} ]
	then
		nmkdup_size=\"\$(du -b \${nbam_mkdup} | cut -f1)\"
		nfinal_size=\"\$(du -b \${nbam_final} | cut -f1)\"
		nidra_size=\"\$(du -b \${nbam_indelra} | cut -f1)\"

		if [ \${nmkdup_size} -gt \${nidra_size} ] || [ \${nfinal_size} -lt \${nidra_size} ] || [ \${nfinal_size} -lt \$oneGB ] || [ \${nidra_size} -lt \$oneGB ]
		then
			printf \"\${sample}_normal\\\n\" >> \${refine_failed_samples}
			(( normal_errors ++ ))
		fi
	fi


	####################
	##Submit next step##
	####################

	if [ \${normal_errors} -lt 1 ] && [ \${tumor_errors} -lt 1 ]
	then
		echo \"qsub \${sample}_varscan.pbs | awk -F"." '{print \\\$1\\\\\"\\\t\$sample\\\\\"}'>> \${varscan_job_ID}\">>\${varscan_script}

		echo \"qsub \${sample}_strelka.pbs | awk -F"." '{print \\\$1\\\\\"\\\t\$sample\\\\\"}'>> \${strelka_job_ID}\">>\${strelka_script}
	fi	
done
" > ${project_dir}/jobs/check_and_go/refine_check.sh

chmod 770 ${project_dir}/jobs/check_and_go/refine_check.sh