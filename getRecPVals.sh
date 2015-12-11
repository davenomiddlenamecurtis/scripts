for m in  SSS.*
# for m in  SSS.rec80.3
# SSS*3
do 
cd $m
filename=$m.pvals.txt
echo $line > $filename
ls -1 *sao | while read file 
do
line=$file
while read w1 w2 w3 w4
do
if [ "$w1" == "-log(p)" ]
then
line="$line $w3"
echo $line
echo $filename
fi
if [[ ( "$w1" == "Controls" && "$w2" != "Cases" ) || "$w1" == "Cases"   ]]
then
line="$line $w1 $w2 $w3 $w4"
fi
done < $file
echo $line >> $filename
done 
mv $filename ..
cd ..
done