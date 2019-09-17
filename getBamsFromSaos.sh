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

model=ct08.rare
# disease=WKS
# searchString=mcquillin
searchString=IBDAJ
disease=IBDAJ
bams="/cluster/project8/IBDAJE/ExomeSequences/BGI/AJ/align/data/"
isCram=yes
if [ -z $model -o -z $disease -o -z $genes -o -z $bams ]
then
	echo need to set disease model genes bams
	exit
fi

echo $model $disease $genes $bams 

testName=$disease.$model

if [ .$testName == . ]
then
	echo Need to set testName
	exit
fi

software=/cluster/project8/vyp/vincent/Software
samtools=${software}/samtools-1.1/samtools
 
workFolder=/cluster/project8/bipolargenomes/$disease/$testName
resultsFolder=$workFolder/results
varFolder=$workFolder/vars
if [ ! -e $varFolder ]
then
	mkdir $varFolder
fi

for gene in $genes
do
	l=0
	varFile=$varFolder/$testName.$gene.varList
	if [ -e $varFile ] ; then rm $varFile; fi
	echo $resultsFolder/$testName.$gene.sao
	cat $resultsFolder/$testName.$gene.sao | while read line
	do
	if [ $l -lt 3 ]
	then
		l=$(( l + 1 ))
		continue
	fi
	words=($line)
	if [ ${words[0]} = Controls ]
	then 
		break
	fi
	echo ${words[6]} ${words[12]}
	if [ $( echo ${words[6]} '<' ${words[12]} | bc -l ) -eq 1 ]
	then
		var=${words[16]}
		chr=${var%%:*}
		pos=${var#*:}
		pos=${pos%%:*}
		echo $var $gene $chr $pos
		echo $gene $chr $pos >> $varFile
	fi
	done
	cat $varFile | while read gene chr pos
	do
		subFile=$varFolder/$testName.$gene.$chr.$pos.subList
		if [ -e $subFile ] ; then rm $subFile; fi
		showAltSubs --arg-file ~/pars/gva.$disease.$model.arg --position $chr:$pos >$subFile
		start=$(( pos - 100 ))
		end=$(( pos + 100 ))
		varScript=showVar.$testName.$gene.$chr.$pos.sh
		if [ -e $varScript ]; then rm $varScript; fi
		cat $subFile | grep $searchString | while read ID al a2
		do
			echo $ID
			ID=${ID##*_}
			echo $ID
if [ "$isCram" = "yes" ]
then
			$samtools view  -b $bams/$ID*unique*cram $chr:$start-$end > $varFolder/$testName.$gene.$chr.$pos.$ID.bam
else
			$samtools view  -b $bams/$ID*unique*bam $chr:$start-$end > $varFolder/$testName.$gene.$chr.$pos.$ID.bam
fi
			$samtools index $varFolder/$testName.$gene.$chr.$pos.$ID.bam
			# echo $samtools view  $bams/$ID*unique*bam $chr:$start-$end
			# $samtools view  $bams/$ID*unique*bam $chr:$start-$end > $varFolder/$testName.$gene.$chr.$pos.$ID.sam
			echo $samtools tview -p $chr:$pos $varFolder/$testName.$gene.$chr.$pos.$ID.bam >> $varScript
		done
	done
done