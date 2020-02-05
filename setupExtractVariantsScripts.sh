#!/bin/bash
# DC script extract variants in genes from WGS dataset, prior to annotation

refdir=reference38
geneList=/home/rejudcu/reference38/refseqgenes.hg38.20191018.allGenes.onePCDHG.txt
# geneList=/home/rejudcu/reference/DRDgenes.txt
disease=ADSP2
model=common

if [ -z $geneList ]
then
 geneList=/home/rejudcu/SSSDNMclinical/notNeuroGenes.lst
# geneList=/home/rejudcu/SSSDNMclinical/dominantGenes.lst
# geneList=/home/rejudcu/SSSDNMclinical/recessiveGenes.lst
fi
# geneList=/home/rejudcu/reference/allGenes140817.onePCDHG.txt
# geneList=/home/rejudcu/reference/DRDgenes.txt
# geneList=/home/rejudcu/tmp/FAM21EP.lst

# disease="UCLEx.Prionb2"
# model="ExAC.ct08.rare"
# model="ct08.cleaned"
# must be in this order or else qdel will delete all the ct08 jobs

if [ -z "$refdir" ]
then
  refdir=reference
fi
if [ -z "$disease" ]
then
  disease=ADSP
fi
if [ -z "$model" ]
then
  model=all
#   model="codeVars.Dam.NotNeuro codeVars.Dis.NotNeuro"
#  model="codeVars.Dam codeVars.Dis"
#  model="codeRecDam codeRecDis"
fi
# doing this so I can copy the annotation files

homeFolder=/cluster/project9/bipolargenomes
argFolder=/home/rejudcu/pars
dataHome=/home/rejudcu
# copyVCF=yes
copyVCF=no
# only attempt to copy vcf files if not too big, else arg file must specify absolute path to vcf files

if [ -z "$disease" -o -z "$model" ]
then
	echo Error in $0: must set environment variables disease and model
	exit
fi

someGenesLeft=no

for d in $disease
do
for m in $model
do

testName=$d.$m
argFile=$argFolder/gva.$testName.arg


# workFolder=/cluster/project8/bipolargenomes/GVA

workFolder=$homeFolder/$d/$testName
mkdir $homeFolder/$d
mkdir $workFolder

nSplits=100 # change this to 10 for the clinical SSSDNM thing
# nSplits=1 # for 30 BP genes

splitScript=$workFolder/scripts/split${nSplits}s.sh
scriptName=$testName.runSplit${nSplits}.sh
mainSplitScript=$workFolder/scripts/$scriptName

qdel $testName.'runSplit*'

nhours=12 # were remaining on queue for 4 hours
vmem=6 
memory=2
queue=queue6
# scratch=10
# apparently I was using 40
scratch=40

if [ ! -e $workFolder ]; then mkdir $workFolder; fi;
wastebin=$workFolder/wastebin
if [ ! -e $wastebin ]; then mkdir $wastebin; fi
if [ ! -e $workFolder/vars ]; then mkdir $workFolder/vars; fi;
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
    outFile=$workFolder/vars/$testName.$geneName.vars.vcf
# I am going to add an exclusion log file so I can find which variants failed which conditions
    if [ ! -e $outFile ]
    then 
		echo "PATH=$softwareFolder:\$PATH 
		set +e
		# this should switch off errexit to prevent script exiting by default if no proper exit code from child process
		tempFolder=$geneName
		mkdir \$tempFolder 
		cd \$tempFolder 
		rm gva*.$geneName.*
		commLine=\"geneVarAssoc --arg-file $argFile --gene $geneName --only-extract-variants 1 --keep-temp-files 1\" 
		echo Running:
		echo \$commLine
		\$commLine 
		echo finished running geneVarAssoc
		cat gva.$geneName.case.1.vcf | grep -v '#' |  cut -f1-9 | sed -e s/chr// > $outFile 
#remove the chr to make it easier to sort
		cd ..
		# avoid upsetting bash by removing the current working directory
		rm -r \$tempFolder" >> $shellScript
    fi
    done

# was \$commLine > gva.$testName.$geneName.elog 
		
nScriptsWritten=`find $workFolder/scripts -name 'runGVA.*.sh' | wc -l`
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
#$ -l tscr=${scratch}G
#$ -l tmem=${vmem}G,h_vmem=${vmem}G
#$ -l h_rt=${nhours}:0:0
#$ -t 1-$nSplits
#$ -V
#$ -R y

# I used to have #$ -cwd but I am going to try just omitting it as sometimes cannot cd to it
# If that does not work may try -wd /scratch0

date
echo bash -x $splitScript \$SGE_TASK_ID
bash -x $splitScript \$SGE_TASK_ID
date
" > $mainSplitScript

echo "
#!/bin/bash
set +e
#  was exiting after running just one, possibly because no proper exit code from script
# this should switch off errexit
echo Running \$0 with argument \$1
mkdir /scratch0/$USER
tmpDir=/scratch0/$USER/\$RANDOM
mkdir \$tmpDir
cd \$tmpDir
mkdir pars
if [ $copyVCF = yes ]
then
	mkdir vcf
	mkdir vcf/$disease
	cp -L $dataHome/vcf/$disease/* vcf/$disease
	# copy destination of links
fi
mkdir $refdir
cp -L $dataHome/$refdir/* $refdir
cp -L $dataHome/pars/* pars
# runGVA.sh will create a temporary folder named after the gene and cd to it
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
rm -r \$tmpDir
" > $splitScript

count=`find $workFolder/scripts -name 'runGVA*sh' | wc -l`

if [ $count -gt 0 ]
then
	echo wrote $count scripts
	echo qsub -N $scriptName $mainSplitScript
	pushd $workFolder
# reason for this is that I would get Eqw with qstat -j error message: error: can't chdir to /home/rejudcu/tmp: No such file or directory 
	qsub -N $scriptName $mainSplitScript
	popd
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
	echo "export disease=\"$disease\"; export model=\"$model\"; export geneList=$geneList; bash $0 &> $workFolder/$logFile.log" | at now + $nhours hours
else
	echo date > $workFolder/$logFile.log
	echo All variant files written OK >> $workFolder/$logFile.log
fi
