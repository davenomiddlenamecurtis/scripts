#$ -S /bin/bash
#$ -l h_vmem=4G
#$ -l tmem=4G
#$ -l h_rt=3600
#$ -j y
#$ -S /bin/bash
#$ -cwd
# trap 'ls -l > ~/problems/gtr.${geneName}.problem.txt' EXIT

# This is mainly designed to be a run as shell script from a submitted job, but could be submitted if desired
# If targetalready exists then it quickly finishes

set -x

if [ .$geneName == . ] ; then echo must specify geneName; exit ; fi
if [ .$model == . ] ; then echo must specify model; exit ; fi
if [ .$destDir == . ] ; then echo must specify destDir; exit ; fi
if [ .$prefix == . ] ; then echo must specify prefix; exit ; fi
# e.g. gva, gtr
if [ .$commStr == . ] ; then echo must specify commStr; exit ; fi
echo geneName is $geneName

PATH=~/bin:${PATH}
PATH=/share/apps/shapeit.v2.r778.static:${PATH}
PATH=/cluster/project8/vyp/vincent/Software/tabix-0.2.5:${PATH}
PATH=/share/apps/impute_v2.3.0:${PATH}

# mkdir /scratch0

tempDir=/scratch0/rejudcu/$model.$geneName
# hope we can manage without the commStr and this will still be sufficiently unique
realDestDir=$destDir/$model
target=$realDestDir/$prefix.$geneName.sao
logFile=$tempDir/$model.$geneName.log
problemDir=$destDir/problems

rm $realDestDir
# this will only happen if there is accidentally a file by this name rather than a directory
mkdir $realDestDir

if [ -e $target ]
then
echo $target already exists
exit
fi

mkdir /scratch0/rejudcu
rm -r $tempDir
mkdir $tempDir
mkdir $destDir
cd $tempDir
pwd
echo Will run this command: $commStr ~/pars/gva.${model}.par $geneName
$commStr ~/pars/gva.${model}.par $geneName > $logFile
if [ .$nodelete == .1 ]
then
mkdir $destDir/kept
cp *.$geneName.* $destDir/kept
fi
if [ ! -f ${prefix}.${geneName}.sao ] 
then
mv *.${geneName}.*sao ${prefix}.${geneName}.sao
fi
if [ -f $prefix.$geneName.sao ]
then
mv $prefix.$geneName.sao $realDestDir
else
mkdir $problemDir
ls -l >> $logFile
cp $logFile $problemDir
fi
rm -r $tempDir



# for f in *txt;do  while read g; do if [ ".`ls ~/results/*${g}.sao 2>error.log `" == "." ]; then echo $f : $g ; fi ; done < $f ;done >missing.txt