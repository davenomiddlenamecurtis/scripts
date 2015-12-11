#!/bin/bash

rm ~/tmp/clearHosts.sh

qhost | while read host rest
do 
echo ssh $host \"rm -r /scratch0/GVA* /scratch0/rejudcu\" >> ~/tmp/clearHosts.sh
done

source ~/tmp/clearHosts.sh
