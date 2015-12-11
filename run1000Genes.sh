#$ -S /bin/bash
# Memory Requests 2Gig
#$ -l h_vmem=2G
#$ -l tmem=2G
#$ -j y
#Directs SGE to run the job in the same directory from which you submitted it. 
#$ -cwd
#$ -l h_rt=12:0:0

PATH=~/bin:${PATH}
PATH=/share/apps/shapeit.v2.r778.static:${PATH}
PATH=/cluster/project8/vyp/vincent/Software/tabix-0.2.5:${PATH}

# parFile=~/pars/gva.SSS.rec15.7.par
if [ .$rootNum == . ]
then
echo must set parFile and rootNum
else
mkdir temp${rootNum}
cd temp${rootNum}
echo parFile is $parFile
echo rootNum is $rootNum
if [ -e ../all${rootNum}000${rootNum}499.out ]
then 
echo  ../all${rootNum}000${rootNum}499.out exists
else
~/msvc/vcf/geneVarAssocAll $parFile all${rootNum}000${rootNum}499.out ${rootNum}000 ${rootNum}499
cp all${rootNum}000${rootNum}499.out ..
fi

if [ -e ../all${rootNum}500${rootNum}999.out ]
then 
echo ../all${rootNum}500${rootNum}999.out exists
else
~/msvc/vcf/geneVarAssocAll $parFile all${rootNum}500${rootNum}999.out ${rootNum}500 ${rootNum}999
cp all${rootNum}500${rootNum}999.out ..
fi

cd ..
# rm -r temp${rootNum}
fi
