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

# try to get usual paths etc.

echo setting PATH

PATH=~/bin:${PATH}
PATH=/share/apps/shapeit.v2.r778.static:${PATH}
PATH=/cluster/project8/vyp/vincent/Software/tabix-0.2.5:${PATH}
# just temporary to check new scoreassoc
PATH=~/newgva:${PATH}

echo Will run this command:
echo eval $commandLine
eval $commandLine

# was
# echo eval sh $commandLine
# eval sh $commandLine

# commandLine="for i in *out; do cat \$i >> allRec15.txt; done"
# qsub -v commandLine="$commandLine" ~/scripts/submitCommand.sh
