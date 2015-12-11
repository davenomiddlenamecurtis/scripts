#$ -S /bin/bash
# Memory Requests 2Gig
#$ -l h_vmem=4G
#$ -l tmem=4G
#$ -j y
#$ -cwd
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -l h_rt=48:0:0


if [ .$nodelete == . ]
then
nodelete=0
fi
export nodelete

model=SSS.rec80.3
export model
prefix=gva
export prefix
destDir=~/recResults
export destDir
commStr=~/msvc/vcf/geneVarAssoc
export commStr

listLogFile=$destDir/${inputGeneList##*/}.$model.log

echo started reading $inputGeneList > $listLogFile
date >> $listLogFile

while read gene 
do 
geneName=$gene
export geneName
echo running sh ~/scripts/runOneGene.sh with $gene $model $prefix >> $listLogFile
sh ~/scripts/runOneGene.sh
done < $inputGeneList
echo completed reading $inputGeneList >> $listLogFile
date >> $listLogFile

# for i in *txt ; do qsub -v inputGeneList=$i -e $i.err ~/scripts/runHapRecFromList.sh ; done
