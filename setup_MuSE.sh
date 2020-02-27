#!/bin/bash

USAGE="setup_MuSE.sh\n\n"

#MuSE setup
git submodule init
git submodule update
printf "\nexport PATH=\"$(pwd)/MuSE/MuSE:\$PATH\"\n" >> ~/.bashrc
cd $(pwd)/MuSE;make;cd -

