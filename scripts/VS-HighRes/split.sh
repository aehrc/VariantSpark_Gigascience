#!/bin/bash

numSam=$1
numVar=$2
PEHNO=dataset.$numSam.$numVar.pheno.no_.csv # phenotype file
GENO=dataset.$numSam.$numVar.csv.bz2  # genotype file
LINES=10000 # line per batch
OUTPUT=dataset.s$numSam.v$numVar.csv.bz2

set -x
aws s3 cp --recursive ./ s3://variant-spark/GigaScience/Data/vs-highRes/

aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$PEHNO ./
aws s3 cp $PEHNO s3://variant-spark/GigaScience/Data/vs-highRes/pheno.csv


cat $PEHNO | datamash transpose -t , | head -n 1 > lbl


aws s3 cp s3://variant-spark/GigaScience/Data/Yggdrasil2/$OUTPUT - | pv | pbzip2 -32 -dc  | awk '{print("x_"NR","$0)}' | cat lbl - | pbzip2 -p96 > $OUTPUT

aws s3 cp ./$OUTPUT s3://variant-spark/GigaScience/Data/vs-highRes/$OUTPUT
v=100
n=101
for i in {1..17}
do
        echo $v " - " $n
        set -x
        cat $OUTPUT | pv | pbzip2 -dc -p32 | head -n $n | pbzip2 -p96 > dataset.s$numSam.v$v.csv.bz2
        aws s3 cp dataset.s$numSam.v$v.csv.bz2 s3://variant-spark/GigaScience/Data/vs-highRes/
        rm dataset.s$numSam.v$v.csv.bz2
        set +x
        v=$(( v*2 ))
        n=$(( v+1 ))
done

exit
