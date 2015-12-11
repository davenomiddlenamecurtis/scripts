#$ -S /bin/bash
# Memory Requests 2Gig
# need 4 for java / GATK ?
#$ -l h_vmem=4G
#$ -l tmem=4G
#$ -j y
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -cwd
#$ -l h_rt=24:0:0

echo sourcing ~/.bash_profile
source ~/.bash_profile

echo sourcing ~/.bashrc
source ~/.bashrc

for n in 1 2
do

dest=`echo *ALL_R$n*fastq.gz`
source=/cluster/project8/bipolargenomes/WKSexomes/savedFastq/${dest//ALL/L00*}
echo $source

# dest=`echo *L006*R$n*fastq.gz`
# dest=${dest//L006/ALL}
echo $dest

echo cat $source into $dest
cat $source > $dest

# echo cat *L00*R$n*fastq.gz into $dest
# cat *L00*R$n*fastq.gz > $dest
# echo mv *L00*R$n*fastq.gz  /cluster/project8/bipolargenomes/WKSexomes/savedFastq
# mv *L00*R$n*fastq.gz  /cluster/project8/bipolargenomes/WKSexomes/savedFastq

done