#! /bin/bash

# The purpose of this script is to configure your environment and install the
# necessary tools for the consensus variant caller pipeline. The script will
# create two conda enviornments, which the script will need to switch between
# because not all the tools are compatible in the same enviroment.

# IMPORTANT NOTES: this script only needs to be run ONCE. You will also need
# to have conda installed in order to configure these two environments.

# Usage: bash config_cvc.sh 3 OR bash config_cvc.sh 2
# The 2 or 3 depends on your miniconda version.

if [ $1 == 2 ] || [ $1 == 3 ]
then
	#if conda env exists update, else create them
	if [ -e strelka_env.yml ] && [ -e main_env.yml ] && [ -e gatk3_env.yml ]
	then
		echo "Updating conda environments"
		conda env update -f strelka_env.yml
		conda env update -f main_env.yml
		conda env update -f gatk3_env.yml
	else
		echo "Creating new conda environments"
		conda env create -f strelka_env.yml
		conda env create -f main_env.yml
		conda env create -f gatk3_env.yml
	fi

	#add scripts to path
	ln -s $(pwd)/run_evc.sh ~/miniconda$1/bin/run_evc
	
	if [ -e strelka_env.yml ] && [ -e main_env.yml ] && [ -e gatk3_env.yml ]
	then
		echo "Successfully installed three environments: evc_main, evc_strelka and evc_gatk3"
	else
		echo "Something didn't work. Please check your conda installation."
	fi
elif [ $1 -ne 2 ] && [ $1 -ne 3 ]
then
	echo "$1 is not a valid input"
	echo "USAGE: bash config_cvc.sh [miniconda version (i.e. 2 or 3)]"
else
	echo "You have to provide an input"
	echo "USAGE: bash config_cvc.sh [miniconda version (i.e. 2 or 3)]"
fi

echo Registering for gatk3...
conda activate evc_gatk3
gatk3-register /projects/ps-lalexandrov/shared/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef/GenomeAnalysisTK.jar
conda deactivate
echo gatk3 registered, environment set up is finished!
