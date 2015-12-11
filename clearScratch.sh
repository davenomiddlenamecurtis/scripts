#!/bin/bash
#$ -S /bin/bash
#$ -e /cluster/project8/bipolargenomes/tmp
#$ -o /cluster/project8/bipolargenomes/tmp
#$ -cwd
#$ -l scr=0G
#$ -l tmem=1G,h_vmem=1G
#$ -l h_rt=20:0:0
#$ -t 1-100
#$ -V
#$ -R y
rm -r /scratch0/GVA* rejudcu

