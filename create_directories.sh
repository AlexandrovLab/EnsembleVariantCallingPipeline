#!/bin/bash

tissues_txt=$1
USAGE="USAGE:\tcreate_directories.sh \\
		txt_of_all_tissues \\
		new_analysis_path \\
		email"


if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
	printf "$USAGE"
	exit 1
fi

for tissue in $(cat $tissues_txt)
do
run_evc \\
/restricted/alexandrov-group/shared/precancer_analysis/tissue_types/${tissue}/paired_end \\
/restricted/alexandrov-group/shared/precancer_analysis/new_analysis/${tissue} \\
/restricted/alexandrov-group/shared/precancer_analysis/tissue_types/${tissue}/paired_end/${tissue}.map \\
${email}
done