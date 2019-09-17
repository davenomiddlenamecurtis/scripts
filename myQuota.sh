#!/bin/bash

getQuota='
{ if (printNext==1) {
  print $0;
}
if ($1=="128.41.96.4:/cluster/homes/biochem/rejudcu" || $1=="128.41.96.4:/cluster/project9/bipolargenomes") {
  printNext=1;
}
else {
  printNext=0;
}
}
'

quota -s | awk "$getQuota"