set -v
rm pgc.scz.snps.txt 
rm pgc.bip.snps.txt 
rm pgc.scz2.snps.txt
echo $1
ls -l $1
cat $1 | while read snp line
do
echo ${snp:0:2}
if [ .${snp:0:2} == .rs ]
then 
echo hello
echo $snp `fgrep -w "$snp" ~/fromPGC/pgc.scz.full.2012-04.txt` >> pgc.scz.snps.txt 
echo $snp `fgrep -w "$snp" ~/fromPGC/pgc.bip.full.2012-04.txt` >> pgc.bip.snps.txt 
# echo $snp `fgrep -w "$snp" ~/fromPGC/daner_PGC_SCZ52_0513a` >> pgc.scz2.snps.txt 
fi
done 
