if [ .$2 == . ] 
then 
echo Usage:
echo getRsNamesFromPos.sh poslist.txt rsnames.txt
else

fi

rm pgc.scz.snps.txt 
while read line; do echo $line `fgrep -w "$line" pgc.scz.full.2012-04.txt` >> pgc.scz.snps.txt ; done < $1
rm pgc.bip.snps.txt 
while read line; do echo $line `fgrep -w "$line" pgc.bip.full.2012-04.txt` >> pgc.bip.snps.txt ; done < $1
