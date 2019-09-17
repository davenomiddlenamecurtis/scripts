#!/bin/bash

cd /cluster/project8/bipolargenomes/$1

for f in *
do
oldSize=$(stat -c%s $f)
newSize=$(stat -c%s /cluster/project9/bipolargenomes/$1/$f)
if [ $oldSize != $newSize ]
then
	echo $f
fi
done

