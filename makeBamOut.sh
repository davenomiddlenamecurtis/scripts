#!/bin/bash

if [ -z "$bam" -o -z "$chr" -o -z "$pos" ]
then
	echo Need to set: bam chr pos
	exit
fi

ID=${bam##*/}
ID=${ID%%_*}

# this is mine:
javaTemp=/scratch0/bam2gVCF$ID
mkdir $javaTemp

source /home/rejudcu/pipeline_scripts/alignParsFile.txt

start=$((pos-1000))
end=$((pos+1000))

$java -Djava.io.tmpdir=${javaTemp} -Xmx8g  -jar $GATK -T HaplotypeCaller -R $fasta -I $bam \
	--dbsnp ${bundle}/dbsnp_137.b37.vcf \
	--emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 \
	-stand_call_conf 30.0 \
	-stand_emit_conf 10.0 \
	-L ${chr}:${start}-${end} \
	--activeRegionExtension 100 \
	-o ${ID}.$chr.$pos.gvcf \
	--bamOutput ${ID}.$chr.$pos.bam \
	--bamWriterType ALL_POSSIBLE_HAPLOTYPES	\
	-forceActive \
	-disableOptimizations \

#	--annotation StrandAlleleCountsBySample \
	
	# --debug 
	
	# --min_mapping_quality_score 30
	
	
export chr=$chr
export pos=$pos
export bam=`pwd`/${ID}.$chr.$pos.bam
bash ~/scripts/showPosInIGV.sh

bamreadcount=/share/apps/genomics/bam-readcount/build/bin/bam-readcount
echo $bamreadcount -f $fasta ${ID}.$chr.$pos.bam 	${chr}:${pos}-${pos}
$bamreadcount -f $fasta ${ID}.$chr.$pos.bam 	${chr}:${pos}-${pos}

	