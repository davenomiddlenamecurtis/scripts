#!/bin/bash

if [ -z $2 ]
then
	echo Usage: $0 oldGeneList.txt newGeneList.txt
fi

cat $1 | sed -e "s/\sPCDHG[A-Za-z0-9]*\s/\tPCDHG\t/g" > $2
