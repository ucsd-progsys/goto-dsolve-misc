#!/bin/bash
cmd="../../dsolve.py -fix "
out="log"

rm $out
for i in *.ml 
do
  cmdi=$cmd$i
  echo $cmd
  $cmdi >> $out 
done

