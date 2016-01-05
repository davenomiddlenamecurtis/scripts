#!/bin/bash

# DC script to set up GVA analyses, one script per gene, move all reference files to scratch0 first, run 100 scripts

# On new cluster exits as soon as one analysis done. I suspect this is because errexit is set (set -e, set -o errexit), so I am inserting set +e to switch it off

# set -x

# set +e
# may be useful to have it during main script

# OLDCLUSTER=yes
# geneList=/home/rejudcu/reference/DRDgenes.txt
geneList=/home/rejudcu/reference/allGenes101115.txt

disease="WKS"
model="ct08 ct08.rare"
# must be in this order or else qdel will delete all the ct08 jobs

if [ -z "$disease" -o -z "$model" ]
then
	echo Error in $0: must set environment variables disease and model
	exit
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
# scratchHome=/cluster/scratch4/rejudcu_scratch/GVA
scratchHome=/scratch0/GVA.$testName

nSplits=100

splitScript=$workFolder/scripts/split${nSplits}s.sh
scriptName=$testName.runSplit${nSplits}.sh
mainSplitScript=$workFolder/scripts/$scriptName

qdel $testName.'runSplit*'

nhours=6
vmem=2 
memory=2
scratch=120

if [ ! -e $workFolder ]; then mkdir $workFolder; fi;
wastebin=$workFolder/wastebin
if [ ! -e $wastebin ]; then mkdir $wastebin; fi
if [ ! -e $workFolder/results ]; then mkdir $workFolder/results; fi;
if [ -e $workFolder/error ]; then mv $workFolder/error $wastebin/error; ( rm -r $wastebin/error & ) ; fi;
mkdir $workFolder/error
if [ -e $workFolder/scripts ]; then mv $workFolder/scripts $wastebin/scripts; (rm -r $wastebin/scripts & ); fi;
mkdir $workFolder/scripts; 

cat $geneList | while read geneName
	do
	shellScript=$workFolder/scripts/runGVA.$testName.$geneName.sh
	if [ -e $shellScript ] ; then rm $shellScript; fi
	outFile=$workFolder/results/$testName.$geneName.sao
	scoreFile=$workFolder/results/$testName.$geneName.sco
	if [ ! -e $outFile ]
	then 
		echo "PATH=$softwareFolder:\$PATH 
		if [ .\$scratchFolder = . ] 
		then 
			tempFolder=$workFolder/temp/$geneName
			# in fact, this will not be used unless $workFolder/temp already exists
		else
			tempFolder=\$scratchFolder/temp/$geneName
			mkdir \$scratchFolder/temp
		fi
		mkdir \$tempFolder 
		cd \$tempFolder 
		rm gva.$geneName.*
		if [ .\$localArgFile = . ]
		then
			commLine=\"geneVarAssoc --arg-file $argFile --write-score-file 1 --gene $geneName\" 
		else
			commLine=\"geneVarAssoc --arg-file \$argFileCopy --arg-file \$localArgFile --write-score-file 1 --gene $geneName\" 
		fi
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
mkdir $scratchHome
echo bash $splitScript \$SGE_TASK_ID
bash -x $splitScript \$SGE_TASK_ID
date
" >> $mainSplitScript

cat $mainSplitScript
ls -l $mainSplitScript

echo "
echo Running \$0 with argument \$1
echo Script now looks like this:
cat \$0

scratchFolder=$scratchHome/temp\$1
export scratchFolder
mkdir \$scratchFolder
rm -r \$scratchFolder/*
df -h
localArgFile=\$scratchFolder/localArgFile.arg
export localArgFile
cp $argFile \$scratchFolder
argFileCopy=\$scratchFolder/${argFile##*/}
export argFileCopy
echo --clear-cont 1 > \$localArgFile
echo --clear-case 1 >> \$localArgFile
date
cat \$argFileCopy | while read arg file
do
if [ \$arg = --reference-path ]
then
	mkdir \$scratchFolder/reference
	cp \$file/chr*.fa \$scratchFolder/reference
	echo --reference-path \$scratchFolder/reference >> \$localArgFile
fi
if [ \$arg = --case-file -o \$arg = --cont-file -o \$arg = --case-freq-file -o \$arg = --cont-freq-file -o \$arg = --ref-gene-file -o \$arg = --bait-file -o \$arg = --phenotype-file ]
then
	cp \$file.tbi \$scratchFolder # expands * in tbi file name
	# cp \$file \$scratchFolder # expands * in vcf file name
	for f in \$file
	do
		cp \$f \$scratchFolder
		sourceSize=\$(stat -c%s \$f)
		fileName=\${f##*/}
		destSize=\$(stat -c%s \$scratchFolder/\$fileName)
		if [ \$sourceSize -ne \$destSize ]
		then
			echo Could not copy \$f to \$scratchFolder/\$fileName, probably ran out of scratch space
			ls -l \$scratchFolder
			du \$scratchFolder
			cd \$scratchFolder
			df
			cd
			rm -r \$scratchFolder
			exit
		fi
	done
	fileName=\${file##*/}
	newLine=\"\$arg \$scratchFolder/\$fileName\"
	echo \"\$newLine\" >> \$localArgFile # avoid echo expanding filespec
	# echo \$arg "\$scratchFolder/\$fileName" >> \$localArgFile # do not replace variables but do not expand * in vcf file names
fi
done
df -h
date
echo wrote \$localArgFile, which looks like this:
cat \$localArgFile
echo ls -l \$scratchfolder

set +e
#  was exiting after running just one, possibly because no proper exit code from script
# this should switch off errexit

n=1
find $workFolder/scripts -name 'runGVA*sh' | while read f
do
if [ .\$n = .\$1 ]
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
rm -r \$scratchFolder
" > $splitScript

echo wrote  $mainSplitScript

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
