#!/bin/bash

USAGE="USAGE:\talign_check.sh \\
		map_file \\
		full_path_to_project_directory\n\n"

map_file=$1
project_dir=$2


printf "#!/bin/bash
oneGB=1000000

cd ${project_dir}

#create unique report file name and report the time it was run
align_failed_samples=${project_dir}/jobs/check_and_go/align_\$(date|awk '{OFS=\"-\";\$1=\$1;print}').error
refine_script=${project_dir}/jobs/check_and_go/refine.sh
target_interval_job_ids=${project_dir}/jobs/check_and_go/TargetInterval_job_IDs.txt
resubmit_align_job_ids=${project_dir}/jobs/check_and_go/resubmit_align_job_IDs.txt
resubmit_align_script=${project_dir}/jobs/check_and_go/resubmit_align.sh

printf \"Check align was performed at \$(date)
########### ERROR report ##########\\\n\" > \${align_failed_samples}

printf \"#!/bin/bash
#Run this after align is done\\\n
cd ${project_dir}/jobs/refine/\\\n\\\n\" > \${refine_script}

printf \"\" > \${target_interval_job_ids}

printf \"\" > \${resubmit_align_job_ids}

printf \"#!/bin/bash
#Run this after align is done\\\n
cd ${project_dir}/jobs/align/\\\n\\\n\" > \${resubmit_align_script}

chmod 770 \${align_failed_samples} \${refine_script} \${target_interval_job_ids} \${resubmit_align_script} \${resubmit_align_job_ids}

error_file=${project_dir}/jobs/align/*_align.e
grep -i -n \"error\\\|fail\\\|killed\" \${error_file} >> \${align_failed_samples}


for sample in \$(tail -n+2 ${map_file} | cut -f1)
do
	#stop when there are errors
	tumor_errors=0
	normal_errors=0


	###################
	##Check num files##
	###################
	
	bampath=${project_dir}/\$sample
	tbam_raw=\${bampath}/\${sample}_tumor_raw.bam
	tbam_mkdup=\${bampath}/\${sample}_tumor_mkdp.bam
	nbam_raw=\${bampath}/\${sample}_normal_raw.bam
	nbam_mkdup=\${bampath}/\${sample}_normal_mkdp.bam

	#check if mkdp and raw files exist
	if [ \${tumor_errors} -lt 1 ] && ( [ ! -e \${tbam_mkdup} ] || [ ! -e \${tbam_raw} ] )
	then
		printf \"\${sample}_tumor: missing raw or mkdp BAM file\\\n\" >> \${align_failed_samples}
		(( tumor_errors ++ ))
	fi

	if [ \${normal_errors} -lt 1 ] && ( [ ! -e \${nbam_mkdup} ] || [ ! -e \${nbam_raw} ] )
	then
		printf \"\${sample}_normal: missing raw or mkdp BAM file\\\n\" >> \${align_failed_samples}
		(( normal_errors ++ ))
	fi


	####################
	##Check file sizes##
	####################

	#bam <1gb means error
	if [ \${tumor_errors} -lt 1 ]
	then
		tmkdup_size=\"\$(du -b \${tbam_mkdup} | cut -f1)\"
		traw_size=\"\$(du -b \${tbam_raw} | cut -f1)\"
		
		if [ \${tmkdup_size} -lt \$oneGB ] || [ \${traw_size} -lt \$oneGB ]
		then
			printf \"\${sample}_tumor: One or more files too small\\\n\" >> \${align_failed_samples}
			(( tumor_errors ++ ))
		fi
	fi

	if [ \${normal_errors} -lt 1 ]
	then
		nmkdup_size=\"\$(du -b \$nbam_mkdup | cut -f1)\"
		nraw_size=\"\$(du -b \$nbam_raw | cut -f1)\"

		if [ \${nmkdup_size} -lt \$oneGB ] || [ \${nraw_size} -lt \$oneGB ]
		then
			printf \"\${sample}_normal: One or more files too small\\\n\" >> \${align_failed_samples}
			(( normal_errors ++ ))
		fi
	fi

	########################
	##Check file truncated##
	########################

	#quickcheck returns nothing if the file is ok
	if [ \${tumor_errors} -lt 1 ]
	then
		tmkdup_check=\"\$(samtools quickcheck \${tbam_mkdup} | wc -l)\"
		traw_check=\"\$(samtools quickcheck \${tbam_raw} | wc -l)\"
		
		if [ \${tmkdup_check} -gt 0 ] || [ \${traw_check} -gt 0 ]
		then
			printf \"\${sample}_tumor: Bam file truncated\\\n\" >> \${align_failed_samples}
			(( tumor_errors ++ ))
		fi
	fi

	if [ \${normal_errors} -lt 1 ]
	then
		nmkdup_check=\"\$(samtools quickcheck \${nbam_mkdup} | wc -l)\"
		nraw_check=\"\$(samtools quickcheck \${nbam_raw} | wc -l)\"

		if [ \${nmkdup_check} -gt 0 ] || [ \${nraw_check} -gt 0 ]
		then
			printf \"\${sample}_normal: Bam file truncated\\\n\" >> \${align_failed_samples}
			(( normal_errors ++ ))
		fi
	fi

	####################
	##Submit next step##
	####################

	if [ \${normal_errors} -lt 1 ] && [ \${tumor_errors} -lt 1 ]
	then
		echo \"qsub \${sample}_targetInterval.pbs | awk -F"." '{print \\\$1\\\\\"\\\t\$sample\\\\\"}'>> \${target_interval_job_ids}\">>\${refine_script}
	fi

	if [ \${tumor_errors} -gt 0 ]
	then
		echo \"qsub \${sample}_Talign.pbs | awk -F"." '{print \\\$1\\\\\"\\\t\$sample tumor\\\\\"}'>> \${resubmit_align_job_ids}\">>\${resubmit_align_script}
	fi

	if [ \${normal_errors} -gt 0 ]
	then
		echo \"qsub \${sample}_Nalign.pbs | awk -F"." '{print \\\$1\\\\\"\\\t\$sample normal\\\\\"}'>> \${resubmit_align_job_ids}\">>\${resubmit_align_script}
	fi
done
" > ${project_dir}/jobs/check_and_go/align_check.sh

chmod 770 ${project_dir}/jobs/check_and_go/align_check.sh
