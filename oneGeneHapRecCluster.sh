#$ -S /bin/bash
#$ -l h_vmem=4G
#$ -l tmem=4G
#$ -l h_rt=3600
#$ -j y
#$ -S /bin/bash
#$ -cwd
# trap 'ls -l > ~/problems/gtr.${geneName}.problem.txt' EXIT

# in case I need standalone script

set -v
echo geneName is $geneName

if [ .$geneName == . ] ; then exit ; fi

PATH=~/bin:${PATH}
PATH=/share/apps/shapeit.v2.r778.static:${PATH}
PATH=/cluster/project8/vyp/vincent/Software/tabix-0.2.5:${PATH}
PATH=/share/apps/impute_v2.3.0:${PATH}

# mkdir /scratch0

if [ -e ~/results/gtr.${geneName}.sao ]
then
echo ~/results/gtr.${geneName}.sao already exists
exit
fi

mkdir /scratch0/rejudcu
mkdir ~/results
mkdir ~/problems
rm -r /scratch0/rejudcu/${geneName}
mkdir /scratch0/rejudcu/${geneName}
mkdir /scratch0/problems
cd /scratch0/rejudcu/${geneName}
pwd
echo Will run this command: ~/msvc/vcf/genePhaseRec ~/pars/gva.SSS.haprec.par ${geneName}
~/msvc/vcf/genePhaseRec ~/pars/gva.SSS.haprec.par ${geneName} > /scratch0/problems/gtr.${geneName}.log 2>&1
if [ .$nodelete == .1 ]
then
mkdir ~/kept
cp gtr.${geneName}.* ~/kept
fi
if [ -e gtr.${geneName}.sao ]
then
mv gtr.${geneName}.sao ~/results
rm /scratch0/problems/gtr.${geneName}.log
else
mkdir ~/problems
cp /scratch0/problems/gtr.${geneName}.log ~/problems
ls -l > ~/problems/gtr.${geneName}.problem.txt
fi
rm -r /scratch0/rejudcu/${geneName}



# for f in *txt;do  while read g; do if [ ".`ls ~/results/*${g}.sao 2>error.log `" == "." ]; then echo $f : $g ; fi ; done < $f ;done >missing.txt