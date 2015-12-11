geneList=/home/rejudcu/reference/allGenes.txt
testName=BPrare
workFolder=/cluster/project8/bipolargenomes/GVA
summFile=/home/rejudcu/BPGenomes/$testName.summ.txt

resultsFolder=$workFolder/results

echo Gene MLP > $summFile
cat $geneList | while read geneName
	do
	cat $resultsFolder/*.$geneName.sao | while read w1 w2 w3
		do
		if [ "$w1" == "SLP" ]
		then
		echo $geneName $w3 >> $summFile
		break
		fi
		done
	done
