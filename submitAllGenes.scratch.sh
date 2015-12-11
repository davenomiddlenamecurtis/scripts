if [ .$1 = . ]
then
echo Usage: submitAllGenes.scratch.sh scratchparfile
exit
fi

for i in  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
do
echo running: qsub -cwd -v rootNum=$i,parFile=$1 ~/scripts/run1000Genes.scratch.sh
qsub -cwd -v rootNum=$i,parFile=$1 ~/scripts/run1000Genes.scratch.sh
done
