#!/bin/bash

. setPeer.sh $1
#export X=$(python -c "print('-'*10000)")

for i in {1..5}
do
   export K="Key$i"
   L=$(($i*1000))
   export V=$(python -c "print('-'*$L)")
   echo "Add transaction of length $L "
   . invoke.sh \"$K\" \"$V\" 
done


