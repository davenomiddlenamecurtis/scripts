#$ -S /bin/bash
# Memory Requests 2Gig
#$ -l h_vmem=4G
#$ -l tmem=4G
#$ -j y
#$ -cwd
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -l h_rt=6:0:0

set -x

if [ .$nodelete == . ]
then
nodelete=0
fi
export nodelete

if [ .model == . ]
then
echo Must set model in the environment e.g. SSS.ct13.rare - will use gva.SSS.ct13 and results will end up in ~/GVAresults/SSS.ct13.rare
exit
fi

prefix=gva
export prefix
destDir=~/GVAresults/$model
export destDir
commStr=~/msvc/vcf/geneVarAssoc
export commStr

# model=$model.scratch
# export model

mkdir ~/GVAresults

listLogFile=$destDir/${inputGeneList##*/}.$model.log

echo started reading $inputGeneList > $listLogFile
date >> $listLogFile

cp -r ~/reference /scratch0/rejudcu
cp -r ~/sequence /scratch0/rejudcu
touch ` find /scratch0/rejudcu/sequence -name '*tbi' `
# make sure tbi files are newer than gz

while read gene 
do 
geneName=$gene
export geneName
echo running sh ~/scripts/runOneGene.sh with $gene $model $prefix >> $listLogFile
sh ~/scripts/runOneGene.sh
done < $inputGeneList
echo completed reading $inputGeneList >> $listLogFile
date >> $listLogFile

echo done > $destDir/${inputGeneList##*/}.$model.done

# cd ~/UK10K; for i in ~/geneLists/*txt ; do for d in *; do cd $d; qsub -v inputGeneList=$i,model=$d -e $i.err ~/scripts/runGvaFromList.sh ; cd ..; done; sleep 1m; done

