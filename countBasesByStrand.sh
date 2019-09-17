#!/bin/bash

# bam=4266-3.2.163291848.bam
# chr=2
# pos=163291848

if [ -z "$bam" -o -z "$chr" -o -z "$pos" ]
then
	echo Need to set: bam chr pos
	exit
fi

source /home/rejudcu/pipeline_scripts/alignParsFile.txt

# need to cope with situation where only one bases has reads
# does not always work at present

findBases='
{ for ( i=0; i<4; ++i ) {
	ii=i+6;
	baseString[i]=$ii;
	}
for ( i=0; i<4; ++i ) {
#	print baseString[i];
	split(baseString[i],a,":");
#	print a[2]," ",a[6]," ",a[7];
	total[i]=a[2];
	}
max[0]=0;
max[1]=0;
maxIndex[0]=-1;
maxIndex[1]=-1;
for ( i=0; i<4; ++i ) {
	if (total[i]>max[0]) {
		max[1]=max[0];
		maxIndex[1]=maxIndex[0];
		max[0]=total[i];
		maxIndex[0]=i;
		}
	else if (total[i]>max[1]) {
		max[1]=total[i];
		maxIndex[1]=i;
		}
	}
for ( i=0; i<2; ++i ) {
	if (maxIndex[i]>-1) {
		split(baseString[maxIndex[i]],a,":");
		print a[2]," ",a[6]," ",a[7];
		}
	else {
		print "0 0 0";
		}
	}
}
'
# outString="2       163291848       C       159     =:0:0.00:0.00:0.00:0:0:0.00:0.00:0.00:0:0.00:0.00:0.00  A:2:70.00:8.50:70.00:2:0:0.36:0.01:8.50:2:0.41:75.00:0.41       C:157:69.94:26.98:69.51:73:84:0.53:0.00:1.18:73:0.36:77.66:0.38     G:0:0.00:0.00:0.00:0:0:0.00:0.00:0.00:0:0.00:0.00:0.00  T:0:0.00:0.00:0.00:0:0:0.00:0.00:0.00:0:0.00:0.00:0.00  N:0:0.00:0.00:0.00:0:0:0.00:0.00:0.00:0:0.00:0.00:0.00"
result=`$bamreadcount -f $fasta $bam $chr:$pos-$pos | grep $pos | awk "$findBases"`

# result=`echo $outString | awk "$findBases "`
echo $result
