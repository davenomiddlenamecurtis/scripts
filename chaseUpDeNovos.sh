#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l scr=10G
#$ -l tmem=12G,h_vmem=12G
#$ -l h_rt=6:0:0
#$ -V
#$ -R y
#$ -e /home/rejudcu/tmp
#$ -o /home/rejudcu/tmp

# set -e
# do not set -e because gatk does not exit 0

model=ct08.single
disease=SSSDNMnew
margin=1000 # big enough to allow realigning to work OK
bamFolder=/cluster/project9/bipolargenomes/SSSDNM/bam
vcfPrefix=/cluster/project9/bipolargenomes/SSSDNM/vcf/SSSDNM
genes='*'

if [ -z "$model" -o -z "$disease" -o -z "$genes" -o -z "$bamFolder" -o -z "$vcfPrefix" ]
then
	echo need to set disease model genes bamFolder vcfPrefix
	exit
fi

echo $model $disease $genes $bams 

testName=$disease.$model

source /home/rejudcu/pipeline_scripts/alignParsFile.txt
javaTemp=/scratch0/chaseUpDeNovos
mkdir $javaTemp

set -x 

workFolder=/cluster/project9/bipolargenomes/$disease/$testName
resultsFolder=$workFolder/results
readFolder=$workFolder/reads
realignedReadFolder=$workFolder/realignedReads
batchFolder=$workFolder/batch
resultsFile=$workFolder/deNovos.txt
rm -f $resultsFile
if [ ! -e $readFolder ]
then
	mkdir $readFolder
fi
if [ ! -e $realignedReadFolder ]
then
	mkdir $realignedReadFolder
fi
if [ ! -e $batchFolder ]
then
	mkdir $batchFolder
fi

for f in $resultsFolder/*.$genes.*sao
# for f in $resultsFolder/*.sao
do
	tmpFile=/home/rejudcu/tmp/deNovos.txt
	rm -f $tmpFile
	fgrep mutation $f > $tmpFile
	if [ ! -s $tmpFile ]
		then continue
	fi
	exec 3< $tmpFile
	while read -u 3 line 
	do
		echo $line
		words=($line)
		if [ ${words[0]} != De ]
		then
			continue
		fi
		for (( i=0; i<3; ++i ))
		do
			geno=${words[i+13]}
			PID[$i]=${geno%:??}
		done
		trio=${PID[0]%-1}
		var=${words[16]}
		var=${var%::*}
		chrNum=${var%%:*}
		pos=${var#*:}
		export pos=${pos%%:*}
		start=$(( pos - $margin ))
		end=$(( pos + $margin ))
		gene=${f%.sao}
		gene=${gene##*.}
		
# First, get old and new calls from VCF files
		allCalls=""
		export vcf=/home/rejudcu/sequence/SSSDNM/vcf/CMB-trios_New.dbGAP.vcf.gz
		export chr=chr$chrNum
		for (( i=0; i<3; ++i ))
		do
			export ID=${PID[$i]}
			oldCall[$i]=`bash /home/rejudcu/scripts/showCallFromVcf.sh`
			allCalls="$allCalls ${oldCall[i]}"
		done
		export vcf=$vcfPrefix.$chrNum.vcf.gz
		export chr=$chrNum
		for (( i=0; i<3; ++i ))
		do
			export ID=${PID[$i]}
			newCall[$i]=`bash /home/rejudcu/scripts/showCallFromVcf.sh`
			allCalls="$allCalls ${newCall[i]}"
		done
		
		vcf=$vcfPrefix.$chr.vcf.gz
		chr=$chr
		allCounts=""
		for (( i=0; i<3; ++i ))
		do
# Now extract reads
			extractedBam=$readFolder/${PID[$i]}.$gene.$chr.$pos.bam
			if [ ! -e $extractedBam ]
			then
			if [ "$isCram" = "yes" ]
			then
				$samtools view  -b $bamFolder/${PID[$i]}_sorted_unique.cram $chr:$start-$end > $extractedBam
			else
				$samtools view  -b $bamFolder/${PID[$i]}_sorted_unique.bam $chr:$start-$end > $extractedBam
			fi
			$samtools index $extractedBam
			fi
lsof | grep rejudcu | wc -l			
# Get realigned reads
	gatkLog=/home/rejudcu/tmp/${PID[$i]}.$gene.$chr.$pos.log
	realignedBam=$realignedReadFolder/${PID[$i]}.$gene.$chr.$pos.bam
	if [ ! -e $realignedBam -o ! -s $realignedBam ]
	then
	df -h $javaTemp
	free
	$java -Djava.io.tmpdir=${javaTemp} -Xmx8g  -Xms8g  -jar $GATK -T HaplotypeCaller -R $fasta -I $extractedBam \
	--dbsnp ${bundle}/dbsnp_137.b37.vcf \
	--emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 \
	-stand_call_conf 30.0 \
	-stand_emit_conf 10.0 \
	-L ${chr}:${start}-${end} \
	--activeRegionExtension 100 \
	-o ${ID}.$chr.$pos.gvcf \
	--bamOutput $realignedBam \
	--bamWriterType ALL_POSSIBLE_HAPLOTYPES	\
	-forceActive \
	-disableOptimizations \
	-dontTrimActiveRegions --emitDroppedReads \
	-log $gatkLog

# I tried adding -Xms8g to -Xmx8g  
	fi
ls -l $realignedBam
lsof | grep rejudcu | wc -l
if [ ! -e $realignedBam ]
then
	exit 1
fi
if [ ! -s $realignedBam ]
then
	rm $realignedBam 
	exit 2
fi
 
# write batch file to display bams in igv
IMGDIR=/home/rejudcu/tmp
	echo "new
load $extractedBam
load $realignedBam
snapshotDirectory $IMGDIR
goto $chr:${start}-${end}
sort position
snapshot
" > $batchFolder/${PID[$i]}.$gene.$chr.$pos.batch



# get read counts
			for countBam in $extractedBam $realignedBam
			do
			export bam=$countBam
			export chr=$chr
			export pos=$pos
			readCounts[i]=`bash /home/rejudcu/scripts/countBasesByStrand.sh`
			if [ "${readCounts[i]}" == "" ]
			then
				readCounts[i]="0 0 0 0 0 0"
			fi
			if [ "${readCounts[i]}" = "0 0 0 0 0 0" ]
			then
				echo got "${readCounts[i]} with export bam=$countBam; export chr=$chr; export pos=$pos "
				exit 1
# this exit did not work if piping into read
			fi
			allCounts="$allCounts ${readCounts[i]}"
			done
		done
		echo $gene chr$chr:$pos $chr $pos $ID $allCalls $allCounts >> $resultsFile
	done 
	exec 3<&-
	# trying to avoid unclosed file handles
done

rm -r $javaTemp

exit 0

# Get realigned reads
	realignedBam=$realignedReadFolder/${PID[$i]}.$gene.$chr.$pos.bam
	$java -Djava.io.tmpdir=${javaTemp} -Xmx8g  -jar $GATK -T HaplotypeCaller -R $fasta -I $extractedBam \
	--dbsnp ${bundle}/dbsnp_137.b37.vcf \
	--emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 \
	-stand_call_conf 30.0 \
	-stand_emit_conf 10.0 \
	-L ${chr}:${start}-${end} \
	--activeRegionExtension 100 \
	-o ${ID}.$chr.$pos.gvcf \
	--bamOutput $realignedBam \
	--bamWriterType ALL_POSSIBLE_HAPLOTYPES	\
	-forceActive \
	-disableOptimizations 

