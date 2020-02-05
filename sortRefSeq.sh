#!/bin/bash

if [ -z $1 ] 
then
  echo Script to sort refseq file by gene
  echo $0 refseq.downloaded.table.txt
  exit
fi

name=${1%.txt}
head -n 1 $name.txt > $name.sorted.txt
tail -n +2 $name.txt | sort -k 13 >> $name.sorted.txt

tail -n +2 $name.sorted.txt | cut -f 13 | uniq >  $name.allGenes.txt

cat $name.sorted.txt | sed -E 's/PCDHG\S+/PCDHG/g' > $name.sorted.onePCDHG.txt
tail -n +2 $name.sorted.onePCDHG.txt | cut -f 13 | uniq >  $name.allGenes.onePCDHG.txt


