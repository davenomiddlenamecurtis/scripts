#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l scr=0G
#$ -l tmem=1G,h_vmem=1G
#$ -l h_rt=20:0:0
#$ -V
#$ -R y
#$ -e /home/rejudcu/tmp
#$ -o /home/rejudcu/tmp

model=ct08.single
disease=SSSDNMnew
# searchString=mcquillin
bamFolder=/cluster/project9/bipolargenomes/SSSDNM/bam
vcfPrefix=/cluster/project9/bipolargenomes/SSSDNM/vcf/SSSDNM
isCram=no
if [ -z $model -o -z $disease -o -z $genes -o -z $bamFolder ]
then
	echo need to set disease model genes bams
	exit
fi

echo $model $disease $genes $bams 

testName=$disease.$model

software=/cluster/project8/vyp/vincent/Software
samtools=${software}/samtools-1.1/samtools
 
workFolder=/cluster/project9/bipolargenomes/$disease/$testName
resultsFolder=$workFolder/results
readFolder=$workFolder/reads
if [ ! -e $readFolder ]
then
	mkdir $readFolder
fi
for f in $resultsFolder/*.$genes.*sao
do
	fgrep mutation $f | while read line 
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
		export chr=${var%%:*}
		pos=${var#*:}
		export pos=${pos%%:*}
		start=$(( pos - 100 ))
		end=$(( pos + 100 ))
		gene=${f%.sao}
		gene=${gene##*.}
		varScript=$readFolder/showBams.$gene.sh
		echo export chr=$chr >> $varScript
		echo export pos=$pos >> $varScript
		echo export vcf=$vcfPrefix.$chr.vcf.gz >> $varScript
		echo echo Old and new calls >> $varScript
		echo echo If IDs get printed it means variant was not called >> $varScript
		for (( i=0; i<3; ++i ))
		do
			echo export ID=${PID[$i]} >> $varScript
			echo oldCall[$i]='`bash /home/rejudcu/scripts/showCallFromVcf.sh`' >> $varScript
		done
		echo echo \${oldCall[0]} \${oldCall[1]} \${oldCall[2]} >> $varScript
		echo export chr=chr$chr >> $varScript
		echo export vcf=/home/rejudcu/sequence/SSSDNM/vcf/CMB-trios_New.dbGAP.vcf.gz >> $varScript
		for (( i=0; i<3; ++i ))
		do
			echo export ID=${PID[$i]} >> $varScript
			echo newCall[$i]='`bash /home/rejudcu/scripts/showCallFromVcf.sh`' >> $varScript
		done
		echo echo \${newCall[0]} \${newCall[1]} \${newCall[2]} >> $varScript
		echo read -p \"Press enter for to view reads\" >> $varScript

		echo export vcf=$vcfPrefix.$chr.vcf.gz >> $varScript
		echo export chr=$chr >> $varScript
		for (( i=0; i<3; ++i ))
		do
			if [ "$isCram" = "yes" ]
			then
				$samtools view  -b $bamFolder/${PID[$i]}_sorted_unique.cram $chr:$start-$end > $readFolder/$testName.${PID[$i]}.$gene.$chr.$pos.bam
			else
				$samtools view  -b $bamFolder/${PID[$i]}_sorted_unique.bam $chr:$start-$end > $readFolder/$testName.${PID[$i]}.$gene.$chr.$pos.bam
			fi
			$samtools index $readFolder/$testName.${PID[$i]}.$gene.$chr.$pos.bam
			# echo $samtools view  $bams/$PID*unique*bam $chr:$start-$end
			# $samtools view  $bams/$PID*unique*bam $chr:$start-$end > $varFolder/$testName.$gene.$chr.$pos.$PID.sam
			echo export ID=${PID[$i]} >> $varScript
			echo 'vcfCall=`bash /home/rejudcu/scripts/showCallFromVcf.sh`' >> $varScript
			echo read -p \"Will display reads for ${PID[$i]} at $gene $chr:$pos - vcf entry is \$vcfCall\" >> $varScript
			echo $samtools tview -p $chr:$pos $readFolder/$testName.${PID[$i]}.$gene.$chr.$pos.bam >> $varScript
		done
	done
done