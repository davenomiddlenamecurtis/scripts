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

for d in SSSDNM
do
for n in all ct08.rare
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
workFolder=/cluster/project8/bipolargenomes/SSSDNM/$testName
resultsFolder=$workFolder/results
summFile=$workFolder/$testName.summ.txt

echo Gene$'\t'SLPD$'\t'SLPR$'\t'SLPHA$'\t'SLPHO$'\t'DNM1$'\t'DNM2$'\t'DNM3$'\t'NM1$'\t'NM2$'\t'NM3> $summFile
ls  $resultsFolder/*.*.*.sao | while read resultsFile
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
		if [ "$w1" == "De" ]
		then
			dnm[$ndnm]="$w1 $w2 $w3 $rest"
			ndnm=$(( $ndnm + 1 ))
		fi
		if [ "$w1" == "Non-mendelian" ]
		then
			nm[$nnm]="$w1 $w2 $w3 $rest"
			nnm=$(( $nnm + 1 ))
		fi
		if [ "$w1" == "NB" ]
		then
		echo $geneName$'\t'${column[0]}$'\t'${column[1]}$'\t'${column[2]}$'\t'${column[3]}$'\t'${dnm[0]}$'\t'${dnm[1]}$'\t'${dnm[2]}$'\t'${nm[0]}$'\t'${nm[1]}$'\t'${nm[2]} >> $summFile
# this must be within the read loop because otherwise the variables outside are not set
		break
		fi
		done
	done

done
done
