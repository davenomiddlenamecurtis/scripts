#!/bin/bash

rm ~/tmp/clearHosts.sh

qhost | while read host rest
do 
echo "ssh $host \"cd /scratch0; df -h .; rm -r /scratch0/GVA* /scratch0/rejudcu; df -h . \" " >> ~/tmp/clearHosts.sh
done

source ~/tmp/clearHosts.sh
