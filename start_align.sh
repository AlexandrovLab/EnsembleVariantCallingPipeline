cd /restricted/alexandrov-group/shared/precancer_analysis/new_analysis/SFT/jobs/align
for f in *pbs;do qsub $f|awk -v samp=$f -F"." '{print $1"\t"samp}'>>/restricted/alexandrov-group/shared/precancer_analysis/new_analysis/SFT/jobs/check_and_go/align_job_IDs.txt;done
