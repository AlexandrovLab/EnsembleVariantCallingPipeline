#!/bin/bash


USAGE="USAGE:\trefine_check_template.sh \\
		map_file \\
		full_path_to_project_directory\n\n"

map_file=$1
project_dir=$2

printf "#!/bin/bash

oneGB=1000000
oneMB=1000

cd ${project_dir}

refine_failed_samples=${project_dir}/jobs/check_and_go/postalign_\$(date|awk '{OFS=\"-\";\$1=\$1;print}').error
varscan_script=${project_dir}/jobs/check_and_go/varscan.sh
strelka_script=${project_dir}/jobs/check_and_go/strelka.sh
mutect_script=${project_dir}/jobs/check_and_go/mutect.sh
resubmit_postalign_script=${project_dir}/jobs/check_and_go/resubmit_postalign.sh
resubmit_postalign_job_ids=${project_dir}/jobs/check_and_go/resubmit_postalign_job_IDs.txt
varscan_job_ID=${project_dir}/jobs/check_and_go/varscan_job_IDs.txt
strelka_job_ID=${project_dir}/jobs/check_and_go/strelka_job_IDs.txt
mutect_job_ID=${project_dir}/jobs/check_and_go/mutect_job_IDs.txt

printf \"Check refine was performed at \$(date)
########### ERROR report ##########\\\n\" > \${refine_failed_samples}

printf \"#!/bin/bash
#Run this after postAlign is done\\\n
cd ${project_dir}/jobs/mutect/\\\n\\\n\" > \${mutect_script}

printf \"#!/bin/bash
#Run this after postAlign is done\\\n
cd ${project_dir}/jobs/varscan/\\\n\\\n\" > \${varscan_script}

printf \"#!/bin/bash
#Run this after refine is done\\\n
cd ${project_dir}/jobs/strelka/\\\n\\\n\" > \${strelka_script}

printf \"\" > \${varscan_job_ID}
printf \"\" > \${strelka_job_ID}
printf \"\" > \${mutect_job_ID}

printf \"#!/bin/bash
#Run this after postalign is done\\\n
cd ${project_dir}/jobs/postAlign/\\\n\\\n\" > \${resubmit_postalign_script}

chmod 770 \${refine_failed_samples} \${resubmit_postalign_script} \${varscan_script} \${strelka_script} \${varscan_job_ID} \${strelka_job_ID}


for sample in \$(tail -n+2 ${map_file} | cut -f1)
do
	#stop when there are errors
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

	pon=\${bampath}/\${sample}_PON.vcf.gz
	pon_index=\${bampath}/\${sample}_PON.vcf.gz.tbi



	#check if bam files exist
	if [ ! -e \${tbam_bqsr} ] || [ ! -e \${tbam_final} ] || [ ! -e \${tbai_final} ] || [ ! -e \${tbam_indelra} ] || [ ! -e \${tbai_indelra} ] || [ ! -e \${target_intervals} ]
	then
		printf \"\${sample}_tumor: missing bam files or target intervals\\\n\" >> \${refine_failed_samples}
		(( tumor_errors ++ ))
	fi

	if [ ! -e \${nbam_bqsr} ] || [ ! -e \${nbam_final} ] || [ ! -e \${nbai_final} ] || [ ! -e \${nbam_indelra} ] || [ ! -e \${nbai_indelra} ] || [ ! -e \${target_intervals} ]
	then
		printf \"\${sample}_normal: missing bam files or target intervals\\\n\" >> \${refine_failed_samples}
		(( normal_errors ++ ))
	fi

	#check if PON exists
	if [ ! -e \${pon} ] || [ ! -e \${pon_index} ]
	then
		printf \"\${sample}: missing PON\\\n\" >> \${refine_failed_samples}
		(( normal_errors ++ ))
	fi


	####################
	##Check file sizes##
	####################

	#mkdup too small or either bam <1gb means error
	if [ \${tumor_errors} -lt 1 ] && [ -e \${tbam_final} ]
	then
		tmkdup_size=\"\$(du -b \${tbam_mkdup} | cut -f1)\"
		tfinal_size=\"\$(du -b \${tbam_final} | cut -f1)\"
		tidra_size=\"\$(du -b \${tbam_indelra} | cut -f1)\"
		
		if [ \${tfinal_size} -lt \$oneGB ] || [ \${tidra_size} -lt \$oneGB ]
		then
			printf \"\${sample}_tumor: one or more bam files are too small\\\n\" >> \${refine_failed_samples}
			(( tumor_errors ++ ))
		fi
	fi

	if [ \${normal_errors} -lt 1 ] && [ -e \${nbam_final} ]
	then
		nmkdup_size=\"\$(du -b \${nbam_mkdup} | cut -f1)\"
		nfinal_size=\"\$(du -b \${nbam_final} | cut -f1)\"
		nidra_size=\"\$(du -b \${nbam_indelra} | cut -f1)\"

		if [ \${nfinal_size} -lt \$oneGB ] || [ \${nidra_size} -lt \$oneGB ]
		then
			printf \"\${sample}_normal: one or more bam files are too small\\\n\" >> \${refine_failed_samples}
			(( normal_errors ++ ))
		fi
	fi

	if [ \${normal_errors} -lt 1 ] && [ -e \${pon} ]
	then
		pon_size=\"\$(du -b \${pon} | cut -f1)\"

		if [ \${pon_size} -lt \$oneMB ]
		then
			printf \"\${sample}_normal: PON is too small\\\n\" >> \${refine_failed_samples}
			(( normal_errors ++ ))
		fi
	fi

	########################
	##Check file truncated##
	########################

	#quickcheck returns nothing if the file is ok
	if [ \${tumor_errors} -lt 1 ]
	then
		tfinal_check=\"\$(samtools quickcheck \${tbam_final} | wc -l)\"
		tidra_check=\"\$(samtools quickcheck \${tbam_indelra} | wc -l)\"
		
		if [ \${tfinal_check} -gt 0 ] || [ \${tidra_check} -gt 0 ]
		then
			printf \"\${sample}_tumor: Bam file truncated\\\n\" >> \${refine_failed_samples}
			(( tumor_errors ++ ))
		fi
	fi

	if [ \${normal_errors} -lt 1 ]
	then
		nfinal_check=\"\$(samtools quickcheck \${nbam_final} | wc -l)\"
		nidra_check=\"\$(samtools quickcheck \${nbam_indelra} | wc -l)\"

		if [ \${nfinal_check} -gt 0 ] || [ \${nidra_check} -gt 0 ]
		then
			printf \"\${sample}_normal: Bam file truncated\\\n\" >> \${refine_failed_samples}
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

		echo \"qsub \${sample}_mutect.pbs | awk -F"." '{print \\\$1\\\\\"\\\t\$sample\\\\\"}'>> \${mutect_job_ID}\">>\${mutect_script}
	fi	
	
	if [ \${tumor_errors} -gt 0 ] || [ \${normal_errors} -gt 0 ]
	then
		echo \"qsub \${sample}_postAlign.pbs | awk -F"." '{print \\\$1\\\\\"\\\t\$sample tumor\\\\\"}'>> \${resubmit_postalign_job_ids}\">>\${resubmit_postalign_script}
	fi

done
" > ${project_dir}/jobs/check_and_go/postAlign_check.sh

chmod 770 ${project_dir}/jobs/check_and_go/postAlign_check.sh