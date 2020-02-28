#! /bin/bash
# Usage: setup_env.sh

#conda env update will create an environemnt if it does not exit or update it when exisiting
echo "Updating/Installing conda environments"
conda env update -f strelka_env.yml
conda env update -f main_env.yml
conda env update -f gatk3_env.yml
echo "Successfully installed three environments: evc_main, evc_strelka and evc_gatk3"

#Create links

printf "\nalias run_evc=$(pwd)/run_evc.sh\n" >> ~/.bashrc
printf "alias run_evc_bam=$(pwd)/run_evc_bam.sh\n" >> ~/.bashrc

#MuSE setup
$(pwd)/setup_MuSE.sh $1

echo Registering for gatk3...
source activate evc_gatk3
gatk3-register /projects/ps-lalexandrov/shared/GenomeAnalysisTK-3.8-0-ge9d806836/GenomeAnalysisTK.jar
source deactivate
echo gatk3 registered, environment set up is finished!
