#!/bin/bash

. setPeer.sh $1

for i in {1..5}
do
   export K="Key$i"
   echo "Fetch value $K"
   start=`date +%s.%N`
   . query.sh \"$K\"
   end=`date +%s.%N`
   runtime=$( echo "$end - $start" | bc -l )
   echo $runtime >> fetches.csv
done


