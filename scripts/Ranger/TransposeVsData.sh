#!/bin/bash

PEHNO=$1 # phenotype file
GENO=$2  # genotype file
LINES=$3 # line per batch
OUTPUT=$4

set -x
cut -f 2 -d , $PEHNO > lbl
split -l $LINES $GENO
rm $GENO
set +x

echo "Transpose each part"
for f in x*
do
        echo $f
        datamash transpose -t , < $f > $f.t
        rm $f
done

set -x

paste x*.t | tr \\t , | cut -f 2-1000000000 -d , | paste lbl - | tr \\t , | pigz -p 16 > $OUTPUT
rm lbl x*

# /usr/bin/time -v  ranger --verbose --file $4 --depvarname lable --treetype 1 --ntree 100 --nthreads 8 --outprefix ranger.out 2>&1 | tee ranger.log
# /usr/bin/time -v  ranger --verbose --file $4 --depvarname lable --treetype 1 --ntree 100 --nthreads 8 --outprefix ranger.sm.out --savemem 2>&1 | tee ranger.sm.log

exit
