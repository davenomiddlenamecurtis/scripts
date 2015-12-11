# in case I need standalone script
#$ -l h_vmem=2G
#$ -l tmem=2G
#$ -l h_rt=3600
#$ -j y
#$ -S /bin/bash
# import environment

echo geneName is $geneName

PATH=~/bin:${PATH}
PATH=/share/apps/shapeit.v2.r778.static:${PATH}
PATH=/cluster/project8/vyp/vincent/Software/tabix-0.2.5:${PATH}
rehash
mkdir /scratch0/rejudcu
mkdir /scratch0/rejudcu/UK10K
mkdir ~/resultsUK10K
mkdir /scratch0/rejudcu/UK10K/${geneName}
cd /scratch0/rejudcu/UK10K/${geneName}
~/msvc/vcf/geneTestRec ~/pars/gva.ALLUKSZ.haprec.par ${geneName}
if [ $nodelete == 1 ]
then
mkdir ~/keptUK10K
cp gtr.${geneName}.* ~/keptUK10K
fi
mv gtr.${geneName}.sao ~/resultsUK10K


