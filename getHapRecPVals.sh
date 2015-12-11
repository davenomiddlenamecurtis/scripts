echo $line > hapRecPValsSumm.txt
ls -1 ~/results/SSS.haprec/*sao | while read file 
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
echo $line >> hapRecPValsSumm.txt
done 

