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

geneList=/home/rejudcu/reference/allGenes.txt
# testName=BPrare
# workFolder=/cluster/project8/bipolargenomes/GVA

model="ct08.rare ct08"
disease=WKS

if [ -z $model -o -z $disease ]
then
	echo need to set disease and model
	exit
fi

for d in $disease
do
for n in $model
do 

testName=$d.$n

if [ .$testName == . ]
then
	echo Need to set testName
	exit
fi
# testName=BPrare
 
# workFolder=/cluster/project8/bipolargenomes/GVA
# workFolder=$HOME/UK10K2/$testName
# workFolder=/cluster/project8/bipolargenomes/UK10K2/$testName
workFolder=/cluster/project8/bipolargenomes/$d/$testName
resultsFolder=$workFolder/results
summFile=$workFolder/$testName.summ.txt

echo Gene$'\t'SLPD$'\t'SLPR$'\t'SLPHA$'\t'SLPHO > $summFile
ls  $resultsFolder/*.sao | while read resultsFile
	do
	geneName=$resultsFile
	geneName=${geneName%.*}
	geneName=${geneName##*$testName.}
	index=0
	ndnm=0
	nnm=0
	line=$geneName
	declare -a column
	declare -a dnm
	declare -a nm
	cat $resultsFile | while read w1 w2 w3 rest
		do
		if [ "$w1" == "SLP" ]
		then
			column[$index]=$w3
			index=$(( $index + 1 ))
		fi
		if [ "$w1" == "NB" ]
		then
		echo $geneName$'\t'${column[0]}$'\t'${column[1]}$'\t'${column[2]}$'\t'${column[3]} >> $summFile
# this must be within the read loop because otherwise the variables outside are not set
		break
		fi
		done
	done

done
done
