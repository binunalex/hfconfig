#!/bin/bash

. setPeer.sh $1

for i in {1..5}
do
   export K="Key$i"
   L=$2
   export V=$(python -c "print('-'*$L)")
   echo "Add transaction of length $L "
   start=`date +%s.%N`
   . invoke.sh \"$K\" \"$V\"
   end=`date +%s.%N`
   runtime=$( echo "$end - $start" | bc -l )
   echo $runtime >> writes$2.csv
done


