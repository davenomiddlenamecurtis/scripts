#!/bin/bash
# DC script to set up GVA analyses, one script per gene

for d in ALLUKSZ.ExAC
do
for m in all ct08.rare
do

testName=$d.$m
parFile=/home/rejudcu/pars/gva.$testName.par

if [ .$testName == . ]
then
	echo Need to set testName
	exit
fi
# testName=BPrare

# parFile=/home/rejudcu/pars/gva.BP.1000G.ct08.rare.par
if [ .$parFile == . ]
then
	parFile=/home/rejudcu/pars/gva.$testName.par
#	echo Need to set parFile
#	exit
fi

# geneList=/home/rejudcu/reference/DRDgenes.txt
geneList=/home/rejudcu/reference/allGenes.txt

softwareFolder=/home/rejudcu/bin
 
# workFolder=/cluster/project8/bipolargenomes/GVA

# workFolder=/home/rejudcu/UK10K2/$testName
# workFolder=/cluster/project8/bipolargenomes/UK10K2/$testName
workFolder=/cluster/project8/bipolargenomes/$d/$testName
mkdir $workFolder

mainScript=$workFolder/scripts/runAllGVA.sh
batchScript=$workFolder/scripts/runBatchGVA.sh
fourScript=$workFolder/scripts/runFourGVA.sh
nSplits=100
splitScript=$workFolder/scripts/split${nSplits}s.sh
mainSplitScript=$workFolder/scripts/runSplit${nSplits}s.sh

nhours=20
vmem=6 
memory=2
queue=queue6
scratch=0

if [ ! -e $workFolder ]; then mkdir $workFolder; fi;
if [ ! -e $workFolder/out ]; then mkdir $workFolder/out; fi;
if [ ! -e $workFolder/temp ]; then mkdir $workFolder/temp; fi;
if [ ! -e $workFolder/results ]; then mkdir $workFolder/results; fi;
if [ ! -e $workFolder/error ]; then mkdir $workFolder/error; fi;
if [ ! -e $workFolder/scripts ]; then mkdir $workFolder/scripts; fi;

echo "
#!/bin/bash
#$ -S /bin/bash
#$ -e $workFolder/error
#$ -o $workFolder/error
#$ -cwd
#$ -l scr=${scratch}G
#$ -l tmem=${vmem}G,h_vmem=${vmem}G
#$ -l h_rt=${nhours}:0:0
#$ -t 1-${njobs}
#$ -V
#$ -R y
" > $batchScript

cat $geneList | while read geneName
	do
	shellScript=$workFolder/scripts/runGVA.$testName.$geneName.sh
	if [ -e $shellScript ] ; then rm $shellScript; fi
	outFile=$workFolder/results/$testName.$geneName.sao
	if [ ! -e $outFile ]
	then 
		echo PATH=$softwareFolder:\$PATH > $shellScript
		echo mkdir $workFolder/temp/$geneName >> $shellScript
		echo cd $workFolder/temp/$geneName >> $shellScript
		echo rm "gva.$geneName.*" >> $shellScript
		echo geneVarAssoc $parFile $geneName >> $shellScript
		echo cp "gva.$geneName.*sao" $outFile >> $shellScript
		echo "if [ ! -s $outFile ] ; then rm -f $outFile; fi" >> $shellScript
		echo rm -r $workFolder/temp/$geneName >> $shellScript
		echo sh $shellScript >> $batchScript
	fi
	done

njobs=`ls -l $workFolder/scripts/runGVA*sh | wc -l`

echo "
#!/bin/bash
#$ -S /bin/bash
#$ -e $workFolder/error
#$ -e $workFolder/error
#$ -cwd
#$ -l scr=${scratch}G
#$ -l tmem=${vmem}G,h_vmem=${vmem}G
#$ -l h_rt=${nhours}:0:0
#$ -t 1-${njobs}
#$ -V
#$ -R y
array=( arg0 \`ls $workFolder/scripts/runGVA*sh \`)
script=\${array[ \$SGE_TASK_ID ]}
root=\${script##*/};
root=\${root%.*};
date
echo \$script
sh \$script  
date
" > $mainScript

echo "
#!/bin/bash
#$ -S /bin/bash
#$ -e $workFolder/error
#$ -o $workFolder/error
#$ -cwd
#$ -l scr=${scratch}G
#$ -l tmem=${vmem}G,h_vmem=${vmem}G
#$ -l h_rt=${nhours}:0:0
#$ -t 1-${njobs}
#$ -V
#$ -R y
finished=false
nRunning=0
ls $workFolder/scripts/runGVA*sh | while [  \$finished == false ]
	do
	f=
	read f
	if [ .\$f == . ]
	then
		finished=true
	else
		bash \$f &
		nRunning=\$(( \$nRunning + 1 ))
		if [[ (( \$nRunning > 3 )) ]]
		then
			echo Am waiting, nRunning is \$nRunning
			wait
			nRunning=0
		fi
	fi
	done
" > $fourScript

echo wrote $fourScript

echo "
#!/bin/bash
#$ -S /bin/bash
#$ -e $workFolder/error
#$ -o $workFolder/error
#$ -cwd
#$ -l scr=${scratch}G
#$ -l tmem=${vmem}G,h_vmem=${vmem}G
#$ -l h_rt=${nhours}:0:0
#$ -t 1-$nSplits
#$ -V
#$ -R y
date
echo bash $splitScript \$SGE_TASK_ID
bash -x $splitScript \$SGE_TASK_ID
date
" > $mainSplitScript

echo "
echo Running \$0 \$1
n=1
ls $workFolder/scripts/runGVA*sh | while read f
do
if [ .\$n == .\$1 ]
then
	echo running bash \$f
	bash \$f
fi
if [ \$n == $nSplits ]
then
	n=1
else
	n=\$(( \$n + 1 ))
fi
done
" > $splitScript

echo wrote  $mainSplitScript
ls -l $workFolder/scripts/runGVA*sh | wc

done
done

