#!/bin/bash

#generates simplified versions
#cmd="../../main.native -simp jhala "

#runs solver on each query file
cmd="../../main.native -simplify-t " 
out="log"

if [ $1 ]; then	
  cmd=$1
fi

rm $out
for i in *.in.fq 
do
  cmdi=$cmd$i
  echo $cmdi
  $cmdi >> $out 
done

