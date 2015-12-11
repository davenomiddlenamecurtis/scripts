cd ~/UK10K
for m in AL* OB*
do 
cd $m
filename=$m.pvals.txt
echo $line > $filename
ls -1 $m.scratch/*sao | while read file 
do
line=$file
while read w1 w2 w3 w4
do
if [ "$w1" == "-log(p)" ]
then
line="$line $w3"
fi
if [[ ( "$w1" == "Controls" && "$w2" != "Cases" ) || "$w1" == "Cases"   ]]
then
line="$line $w1 $w2 $w3 $w4"
fi
done < $file
echo $line >> $filename
done 
cd ..
done