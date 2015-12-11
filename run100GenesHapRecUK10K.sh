#$ -S /bin/bash
# Memory Requests 2Gig
#$ -l h_vmem=2G
#$ -l tmem=2G
#$ -j y
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -cwd
#$ -l h_rt=6:0:0

nodelete=0
export nodelete
while read -r gene 
do 
geneName=$gene
export geneName
sh ~/scripts/oneGeneHapRecClusterUK10K.sh
done < $inputGeneList

# for i in *txt ; do qsub -v inputGeneList=$i ~/scripts/run100GenesHapRec.sh ; done
