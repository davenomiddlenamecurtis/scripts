#!/bin/bash

scoreFile=/cluster/project9/bipolargenomes/CMC/pgc_sz_logORs.txt
pValFile=/cluster/project9/bipolargenomes/CMC/pgc_sz_pvals.txt
vcfFile=/cluster/project9/bipolargenomes/MPexomes/vcf/McQuillin_Gurling_UCL_W1_W2_2017.vcf.gz
projectName=MPBPSCZ
# plink=/share/apps/genomics/plink-1.09beta3/plink
plink=/share/apps/genomics/plink-1.9/plink
projectName=MPBPSCZ

vcfFile=/home/rejudcu/vcf/ADSP/ADSP.allchrs.vcf.gz
projectName=ADSP

if [ ! -e $projectName.SNPs.txt ]
then
  awk '{ print $1'} $scoreFile > $projectName.SNPs.txt
fi

if [ ! -e $projectName.all.thinned.bed ]
then
  $plink --vcf $vcfFile\
    -biallelic-only \
    --extract $projectName.SNPs.txt \
	--make-bed --out $projectName.all.thinned
# errors when alt var is * (which means missing)
fi

if [ ! -e $projectName.pca.eigenvec ]
then
  $plink \
  --bfile $projectName.all.thinned \
  --pca header tabs \
  --make-rel \
  --out $projectName.pca
fi
 
if [ ! -e $projectName.PRS.txt -o ! -s $projectName.PRS.txt ]
then 
echo S05 0.00 0.05 > S05.txt
$plink \
  --bfile $projectName.all.thinned \
  --score $scoreFile sum \
  --q-score-range S05.txt $pValFile  \
  --out $projectName.scores

awk '{ print $2, $6 }'  $projectName.scores.S05.profile > $projectName.PRS.txt
fi
