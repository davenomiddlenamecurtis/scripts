source ~/.bashrc
set -x

if [ .$1 == . ]
then
cd ~/UK10K 
for d in OB* ALL*
do sh ~/scripts/runAllGenesFromLists.sh $d &
done
else
model=$1
for i in ~/UK10K/$model/problems/not*lst 
# for i in ~/geneLists/*txt 
# for i in ~/test/*txt 
do
inputGeneList=$i
if [ ! -f ~/UK10K/$model/${inputGeneList##*/}.$model.scratch.done ]
# if txt file already used completely, quickly go to the next one
then
qsub -v inputGeneList=$inputGeneList,model=$model -e $i.err ~/scripts/runGvaFromList.sh
while [ ! -f ~/UK10K/$model/${inputGeneList##*/}.$model.scratch.done ]
do
sleep 2m
done
fi
done 
fi
