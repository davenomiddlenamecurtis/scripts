#!/bin/bash

if [ -z "$vcf" -o -z "$ID" -o -z "$chr" -o -z "$pos" ]
then
	echo Need to set: vcf ID chr pos
	exit
fi

tabix -h $vcf $chr:${pos}-$pos > temp.$ID.$chr.$pos.vcf

GETIDPOS='
index($0,$ID){
for (f=1; f<=NF; f++){
	if ($(f) == ID ){
		print f;
		break
	}
}
}
'

col=`fgrep CHROM temp.$ID.$chr.$pos.vcf | awk -v ID=$ID "$GETIDPOS"`
# may be multiple lines if indel overlaps
grep $pos temp.$ID.$chr.$pos.vcf | awk "{ print \$$col }"
