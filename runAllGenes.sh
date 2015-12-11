#$ -S /bin/bash
# Memory Requests 2Gig
#$ -l h_vmem=2G
#$ -l tmem=2G
#$ -j y
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -cwd
#$ -l h_rt=6:0:0

# this may not be enough time

if [ .$parFile = . ]
then
echo Must set parFile
exit
fi

if [ .$rootNum = . ]
then
rootNum=0
fi

export parFile

# for i in  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
# for i in  0 1 2 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
# do
echo rootNum=$rootNum
export rootNum
sh ~/scripts/run1000Genes.sh
if [ $rootNum = 30 ]
then
exit
else
rootNum=`expr rootNum + 1`
qsub -v parFile=$parFile,rootNum=$rootNum ~/scripts/runAllGenes.sh
fi

#done
