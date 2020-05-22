#$ -S /bin/bash
## this script is called submitCommand.sh
# Memory Requests 2Gig
# need 4 for java / GATK ?
# VEP was randomly crashing with 2, and 4 before splitting by chromosomes, still crashed with 4 on chromosome 12, different places
# now still randomly crashing with 6 so increasing to 8 - no good, try 12 - looks like that fixed it
# #$ -l h_vmem=64G
# #$ -l tmem=64G
#$ -l h_vmem=12G
#$ -l tmem=12G
# #$ -l h_vmem=2G
# #$ -l tmem=2G
#$ -j y
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -cwd
#$ -l h_rt=84:0:0

# echo sourcing ~/.bash_profile
# source ~/.bash_profile

export READALLBASHRC=yes
echo sourcing ~/.bashrc
source ~/.bashrc

# try to get usual paths etc.

echo setting PATH

PATH=/share/apps/shapeit.v2.r778.static:${PATH}
PATH=/cluster/project8/vyp/vincent/Software/tabix-0.2.5:${PATH}
PATH=$DCBIN:${PATH}
date 
echo Will run this command:
echo eval $commandLine
eval $commandLine
date

# was
# echo eval sh $commandLine
# eval sh $commandLine

# commandLine="for i in *out; do cat \$i >> allRec15.txt; done"
# qsub -v commandLine="$commandLine" ~/scripts/submitCommand.sh
