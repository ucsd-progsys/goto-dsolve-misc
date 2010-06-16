#!/bin/bash
cmd="../../main.native -simp jhala "
out="baz"

rm $out
for i in *.in.fq 
do
  cmdi=$cmd$i
  echo $cmd
  $cmdi >> $out 
done

