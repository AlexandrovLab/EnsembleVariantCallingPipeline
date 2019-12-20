#! /bin/bash
# Usage: bash setup_env.sh 3 OR bash config_cvc.sh 2
# The 2 or 3 depends on your miniconda version.

if [ $1 == 2 ] || [ $1 == 3 ]
then
	#conda env update will create an environemnt if it does not exit or update it when exisiting
	echo "Updating conda environments"
	conda env update -f strelka_env.yml
	conda env update -f main_env.yml
	conda env update -f gatk3_env.yml
	echo "Successfully installed three environments: evc_main, evc_strelka and evc_gatk3"
	ln -s $(pwd)/run_evc.sh ~/miniconda$1/bin/run_evc

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
