#!/bin/bash

# e.g. bash ~/scripts//getCommonestVar.sh "SSS2.ct08.vrare/results/*.DRD?.*sao"
# do not forget double quotes

# must add 1 to end position, presumably because of 0/1 indexing
# which raises question about whether I will have the right loci

# http://gatkforums.broadinstitute.org/gatk/discussion/1319/collected-faqs-about-interval-lists

getCount='
BEGIN { maxCount=-1; }
{
count=$4+2*$6+$10+2*$12 ;
if (count>maxCount) {
	maxCount=count;
	split($1,posWords,":");
	if (posWords[1] == "23") { poswords[1]="X"; }
	maxPos=posWords[1] ":" posWords[2] "-" posWords[2] ;
	}
}
END { if (maxCount>0) { print maxPos; } }
'
for f in $1
	do 
	awk "$getCount" $f
	done

# Note extension must be .list

# bash ~/scripts/subComm.sh "$java  -Xmx1g  -Xms1g -Djava.io.tmpdir=${javaTemp} -jar $GATK -T SelectVariants -R $fasta -V /cluster/project9/bipolargenomes/SSS2/vcf/sub/sub20160809/swe.vcf.gz -o SSS2.commonest.vcf -L SSS2.commonest.list"
