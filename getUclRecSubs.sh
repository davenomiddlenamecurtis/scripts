# in case I need standalone script
#$ -l h_vmem=2G
#$ -l tmem=2G
#$ -l h_rt=3600
#$ -j y
#$ -S /bin/bash

fgrep -H STDY  *sao >uclRecSubs.txt 
