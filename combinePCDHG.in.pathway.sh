#!/bin/bash

if [ -z $2 ]
then
	echo Usage: $0 oldGeneList.txt newGeneList.txt
fi

grep -v PCDHG $1 > $2
grep PCDHG $1 | sed -e "s/PCDHG[A-Za-z0-9]*\s//g" | awk ' { print($0 "\tPCDHG" ) } ' >> $2

