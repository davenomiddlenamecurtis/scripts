mkdir /SAN/vyplab/UCLex_raw/dave/oldBam
cd /SAN/vyplab/UCLex_raw/dave/oldBam
rm ../extractThese.txt
for f in ../../*_sorted_unique.bam ; do g=${f##*/}; h=${g%_sorted*} ; echo $h >> ../extractThese.txt; done
or f in ../../*_sorted_unique.bam ; do g=${f##*/}; h=${g%_sorted*} ; ln -s $f  $h.bam ; done
