#!/bin/bash
# subComm.sh

echo Need arguments in single quotes, e.g.:
echo subComm.sh \''for i in *vcf; do bgzip $i; done'\'

if [ $HOSTNAME = elwood.local ]
then
	export DCBIN=~/oldBin
#	export OLDCLUSTER=yes
else
	export DCBIN=~/bin
#	export OLDCLUSTER=no
fi


echo Will run this command:
echo qsub -v DCBIN=$DCBIN,commandLine="$*" ~/scripts/submitCommand.sh
qsub -v DCBIN=$DCBIN,commandLine="$*" ~/scripts/submitCommand.sh