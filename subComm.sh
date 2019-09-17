#!/bin/bash
# subComm.sh

echo Need arguments in single quotes, e.g.:
echo subComm.sh \''for i in *vcf; do bgzip $i; done'\'

echo Will run this command:
echo qsub -v commandLine="$*" /home/rejudcu/scripts/submitCommand.sh
qsub -v commandLine="$*" /home/rejudcu/scripts/submitCommand.sh