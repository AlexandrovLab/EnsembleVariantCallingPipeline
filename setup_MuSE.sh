#!/bin/bash

USAGE="setup_MuSE.sh [miniconda version]\n\n"

if [ -z "$1" ] || ([ "$1" != 3 ] && [ "$1" != 2 ])
then
	printf "$USAGE"
	exit 1
fi

#MuSE setup
git submodule init
git submodule update
ln -s $(pwd)/MuSE/MuSE ~/miniconda$1/bin/MuSE
cd $(pwd)/MuSE;make;cd -

