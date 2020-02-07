#!/bin/bash

numSam=$1
numVar=$2
PEHNO=dataset.$numSam.$numVar.pheno.no_.csv # phenotype file
GENO=dataset.$numSam.$numVar.csv.bz2  # genotype file
LINES=10000 # line per batch
OUTPUT=dataset.s$numSam.v$numVar.csv.bz2

set -x
aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$PEHNO ./
aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$GENO ./
vname=$(head -n 1 $PEHNO | cut -f 4,5,6,7,8 -d , | tr , '|')
cut -f 2 -d , $PEHNO | tail -n +2 > label.csv
cut -f 4,5,6,7,8 -d , $PEHNO | tail -n +2 | datamash transpose -t , > important.csv
cat $GENO | pv | bzcat | grep -v -E "$vname" | tail -n +2 | cut -f 2-1000000000 -d , | cat important.csv - | \
tee >(bash Subset.sh $numSam 10000 1) >(bash Subset.sh $numSam 100000 1) | bash Subset.sh $numSam 20000 1
aws s3 cp --recursive ./ s3://variant-spark/GigaScience/Data/Yggdrasil/

exit

