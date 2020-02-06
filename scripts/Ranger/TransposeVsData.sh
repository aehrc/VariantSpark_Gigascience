#!/bin/bash 

set x

PEHNO=$1 # phenotype file
GENO=$2  # genotype file
LINES=$3 # line per batch
OUTPUT=$4 

cut -f 2 -d , $PEHNO > lbl

split -l $LINES $GENO

for f in x*
do
	datamash transpose -t , < $f > $f.t
done

paste x*.t | tr \\t , | cut -f 2-1000000000 -d , | paste lbl - | tr \\t , > $OUTPUT

rm lbl x*

exit
