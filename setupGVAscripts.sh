#!/bin/bash
# DC script to set up GVA analyses, one script per gene

geneList=/home/rejudcu/reference/allGenes101115.txt

disease="WKS"
model="ct08 ct08.rare"
# must be in this order or else qdel will delete all the ct08 jobs

if [ -z "$disease" -o -z "$model" ]
then
	echo Error in $0: must set environment variables disease and model
	exit
fi

if [ $HOSTNAME = elwood.local ]
then
	export OLDCLUSTER=yes
else
	export OLDCLUSTER=no
fi

if [ "$OLDCLUSTER" = "" ]
then
	echo Error in $0: must set OLDCLUSTER to yes or no
	exit
fi

someGenesLeft=no

for d in $disease
do
for m in $model
do

testName=$d.$m
argFile=/home/rejudcu/pars/gva.$testName.arg

if [ $OLDCLUSTER = yes ]
then
	softwareFolder=/home/rejudcu/oldBin
else
	softwareFolder=/home/rejudcu/bin
fi 
# workFolder=/cluster/project8/bipolargenomes/GVA

# workFolder=/home/rejudcu/UK10K2/$testName
# workFolder=/cluster/project8/bipolargenomes/UK10K2/$testName
workFolder=/cluster/project8/bipolargenomes/$d/$testName
mkdir /cluster/project8/bipolargenomes/$d
mkdir $workFolder

nSplits=100

splitScript=$workFolder/scripts/split${nSplits}s.sh
scriptName=$testName.runSplit${nSplits}.sh
mainSplitScript=$workFolder/scripts/$scriptName

qdel $testName.'runSplit*'

nhours=4
vmem=6 
memory=2
queue=queue6
scratch=0

if [ ! -e $workFolder ]; then mkdir $workFolder; fi;
wastebin=$workFolder/wastebin
if [ ! -e $wastebin ]; then mkdir $wastebin; fi
if [ ! -e $workFolder/results ]; then mkdir $workFolder/results; fi;
if [ -e $workFolder/error ]; then mv $workFolder/error $wastebin/error; ( rm -r $wastebin/error & ) ; fi;
mkdir $workFolder/error
if [ -e $workFolder/scripts ]; then mv $workFolder/scripts $wastebin/scripts; (rm -r $wastebin/scripts & ); fi;
mkdir $workFolder/scripts; 
if [ -e $workFolder/temp ]; then mv $workFolder/temp $wastebin/temp; (rm -r $wastebin/temp & ); fi;
mkdir $workFolder/temp; 

cat $geneList | while read geneName
    do
    shellScript=$workFolder/scripts/runGVA.$testName.$geneName.sh
    if [ -e $shellScript ] ; then rm $shellScript; fi
    outFile=$workFolder/results/$testName.$geneName.sao
	scoreFile=$workFolder/results/$testName.$geneName.sco
    if [ ! -e $outFile ]
    then 
		echo "PATH=$softwareFolder:\$PATH 
		tempFolder=$workFolder/temp/$geneName
		# in fact, this will not be used unless $workFolder/temp already exists
		mkdir \$tempFolder 
		cd \$tempFolder 
		rm gva.$geneName.*
		commLine=\"geneVarAssoc --arg-file $argFile --write-score-file 1 --gene $geneName\" 
		echo Running:
		echo \$commLine
		\$commLine
		echo finished running geneVarAssoc
		cp gva.$geneName.*sco $scoreFile 
		cp gva.$geneName.*sao $outFile 
		if [ ! -s $outFile ] ; then rm -f $outFile $scoreFile; fi
		cd ..
		# avoid upsetting bash by removing the current working directory
		rm -r \$tempFolder" >> $shellScript
    fi
    done

nScriptsWritten=`ls $workFolder/scripts/runGVA.$testName.*.sh | wc -l`
if [ $nScriptsWritten -lt $nSplits ]
then 
	nSplits=$nScriptsWritten
fi 

if [ -e  $mainSplitScript ] ; then rm  $mainSplitScript; fi

echo "
#!/bin/bash
#$ -S /bin/bash
#$ -e $workFolder/error
#$ -o $workFolder/error
#$ -cwd
" >> $mainSplitScript
if [ $OLDCLUSTER = yes ]
then
	echo "#$ -l scr=${scratch}G" >> $mainSplitScript
else
	echo "#$ -l tscr=${scratch}G" >> $mainSplitScript
fi
echo "
#$ -l tmem=${vmem}G,h_vmem=${vmem}G
#$ -l h_rt=${nhours}:0:0
#$ -t 1-$nSplits
#$ -V
#$ -R y
date
echo bash $splitScript \$SGE_TASK_ID
bash -x $splitScript \$SGE_TASK_ID
date
" >> $mainSplitScript

echo "
set +e
#  was exiting after running just one, possibly because no proper exit code from script
# this should switch off errexit
echo Running \$0 with argument \$1
n=1
find $workFolder/scripts -name 'runGVA*sh' | while read f
do
if [ .\$n == .\$1 ]
then
	echo running source \$f # try using source $f instead of bash $f
	source \$f
	echo finished running source \$f
fi
if [ \$n -eq $nSplits ]
then
	n=1
else
	n=\$(( \$n + 1 ))
fi
done
" > $splitScript

count=`find $workFolder/scripts -name 'runGVA*sh' | wc -l`

if [ $count -gt 0 ]
then
	echo wrote $count scripts
	echo qsub -N $scriptName $mainSplitScript
	qsub -N $scriptName $mainSplitScript
	someGenesLeft=yes
else
	echo No genes left to do for $testName	
fi

done
done

logFile=${0##*/}
if [ $someGenesLeft = yes ]
then
	echo will schedule script to run again
	echo "export disease=$disease; export model=$model; bash $0 &> $workFolder/$logFile.log" | at now + $nhours hours
else
	echo date > $workFolder/$logFile.log
	echo All results files written OK >> $workFolder/$logFile.log
fi
