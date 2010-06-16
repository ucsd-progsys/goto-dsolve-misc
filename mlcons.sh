#!/bin/bash
cmd="../../dsolve.py -fix -no-simplify-t "
out="log"

rm $out
for i in *.ml 
do
  cmdi=$cmd$i
  echo $cmdi
  $cmdi >> $out 
done

