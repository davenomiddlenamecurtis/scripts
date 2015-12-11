#$ -S /bin/bash
# Memory Requests 2Gig
#$ -l h_vmem=4G
#$ -l tmem=4G
#$ -j y
#$ -cwd
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -l h_rt=24:0:0

echo started reading $inputGeneList > ~/results/$inputGeneList.log
if [ .$nodelete == . ]
then
nodelete=0
fi
export nodelete
while read gene 
do 
geneName=$gene
export geneName
echo running sh ~/scripts/oneGeneHapRecCluster.sh with $gene >> ~/results/$inputGeneList.log
sh ~/scripts/oneGeneHapRecCluster.sh
done < $inputGeneList
echo completed reading $inputGeneList >> ~/results/$inputGeneList.log

# for i in *txt ; do qsub -v inputGeneList=$i -e $i.err ~/scripts/run100GenesHapRec.sh ; done
