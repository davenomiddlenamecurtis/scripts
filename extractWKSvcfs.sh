#!/bin/bash
#$ -S /bin/bash
#$ -e /cluster/project8/bipolargenomes/tmp
#$ -o /cluster/project8/bipolargenomes/tmp
#$ -cwd
#$ -l scr=0G
#$ -l tmem=4G,h_vmem=4G
#$ -l h_rt=20:0:0
#$ -V
#$ -R y

vcftools=/cluster/project8/vyp/vincent/Software/vcftools_0.1.12a/bin/vcftools
cd /cluster/project8/bipolargenomes/WKS/vcf

# for c in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
for c in 12 
do
	$vcftools --keep /cluster/project8/bipolargenomes/WKS/WKS_IDs.txt --gzvcf mainset_November2015_chr${c}.vcf.gz --out WKS_chr${c} --recode-INFO-all --recode
	bgzip WKS_chr${c}.recode.vcf
done