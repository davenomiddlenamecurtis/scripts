#!/bin/bash

for d in "$@"
do
if [ -d $d ]
then
	toDelete=beingDeleted$RANDOM
	mv $d $toDelete
	rm -r $toDelete &
	mkdir $d 
fi
done

