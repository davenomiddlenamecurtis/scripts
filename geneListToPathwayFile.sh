#!/bin/bash

if [ -z $1 ]
then
	echo Usage: $0 pathwayFilename.parg geneList filenames
	exit
fi

toPathway='
BEGIN { ORS=""; print FILE "\t" FILE "\t" ;}
{ print $1 "\t"; }
END { print "\n"; }
'

pathwayFilename=$1
rm -f $pathwayFilename
shift
while [ $# -gt 0 ]
do
	awk -v FILE=$1 "$toPathway" $1 >> $pathwayFilename
	shift
done
