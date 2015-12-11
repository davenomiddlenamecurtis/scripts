#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l tmem=1G,h_vmem=1G
#$ -l h_rt=4:0:0
#$ -V
#$ -R y
Software=/cluster/project8/vyp/vincent/Software
samtools=${Software}/samtools-1.1/samtools

SRA=SRR1241408

cd /cluster/project8/bipolargenomes/downloads
/home/rejudcu/dbGaP/sratoolkit.2.5.2-centos_linux64/bin/sam-dump --verbose --log-level 5 $SRA 2> $SRA.log | $samtools view -b -o $SRA.bam - >> $SRA.log


