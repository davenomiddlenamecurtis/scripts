#$ -S /bin/bash
# Memory Requests 2Gig
#$ -l h_vmem=2G
#$ -l tmem=2G
#$ -j y
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -cwd
#$ -l h_rt=6:0:0

PATH=~/bin:${PATH}
PATH=/share/apps/shapeit.v2.r778.static:${PATH}
PATH=/cluster/project8/vyp/vincent/Software/tabix-0.2.5:${PATH}

# parFile=~/pars/gva.SSS.rec15.7.par
if [ .$rootNum == . ]
then
echo must set parFile and rootNum
else
cwd=`pwd`
mkdir /scratch0/rejudcu
cp -r ~/reference /scratch0/rejudcu
cp -r ~/sequence /scratch0/rejudcu
touch ` find /scratch0/rejudcu/sequence -name '*tbi' `
# make sure tbi files are newer than gz


mkdir /scratch0/rejudcu/temp${rootNum}
cd /scratch0/rejudcu/temp${rootNum}
echo parFile is $parFile
echo rootNum is $rootNum
~/msvc/vcf/geneVarAssocAll $parFile all${rootNum}000${rootNum}499.out ${rootNum}000 ${rootNum}499
cp all${rootNum}000${rootNum}499.out $cwd
~/msvc/vcf/geneVarAssocAll $parFile all${rootNum}500${rootNum}999.out ${rootNum}500 ${rootNum}999
cp all${rootNum}500${rootNum}999.out $cwd
fi

