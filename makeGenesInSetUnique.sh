#!/bin/bash 

if [ -z $1 ]
then
	echo Usage: $1 inSetFile outUniqueSetFile
	exit
fi

rm -f $2
cat $1 | while read one two genes
do
	( echo $genes | awk ' BEGIN { ORS="\n"; } { for (j=1;j<=NF;++j) print($j) ; } ' | sort | uniq | awk -v one=$one -v two=$two 'BEGIN { ORS = "\t"; print(one,two); } { print } END {print("\n")}' ) >> $2
	dupCount=`echo $genes | awk ' BEGIN { ORS="\n"; print($1,$2); } { for (j=1;j<=NF;++j) print($j) ; } ' | sort | uniq -D | wc -w`
	if [ $dupCount -ne 0 ] 
	then 
		echo $one dupCount = $dupCount
	fi
done
