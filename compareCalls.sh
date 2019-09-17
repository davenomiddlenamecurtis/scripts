#!/bin/bash

vcfPrefix=/cluster/project9/bipolargenomes/SSSDNM/vcf/SSSDNM

if [ -z $trio -o -z $chr -o -z $pos ]
then
	echo need to set trio chr pos
	exit
fi
export chr=$chr
export pos=$pos
export vcf=$vcfPrefix.$chr.vcf.gz
for (( i=1; i<=3; ++i ))
do
	export ID=$trio-$i
	${call[i]}=`bash /home/rejudcu/scripts/showCallFromVcf.sh`
done
echo ${call[1]} ${call[2]} ${call[3]} 
export chr=chr$chr
export vcf=/home/rejudcu/sequence/SSSDNM/vcf/CMB-trios_New.dbGAP.vcf.gz
for (( i=1; i<=3; ++i ))
do
	export ID=$trio-$i
	${call[i]}=`bash /home/rejudcu/scripts/showCallFromVcf.sh`
done

