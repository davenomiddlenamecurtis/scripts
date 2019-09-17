if [ .$1 == . ]
then
	echo packResults.sh resultsDirName
	exit
fi
pushd $1
path=`pwd`
model=${path%/results}
model=${model##*/}
makeScoreTable $model.scores.txt *.sco
tar -czf $model.sao.tgz *.sao *.sco
if [ -e $model.sao.tgz -a -s  $model.sao.tgz ]
then
	 rm *.sao *.sco
fi
rm -r ../error ../scripts ../temp ../wastebin
popd

