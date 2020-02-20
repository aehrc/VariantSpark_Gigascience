#!/bin/bash

numSam=$1
numVar=$2
PEHNO=dataset.$numSam.$numVar.pheno.no_.csv # phenotype file
GENO=dataset.$numSam.$numVar.csv.bz2  # genotype file
LINES=10000 # line per batch
OUTPUT=dataset.s$numSam.v$numVar.csv.bz2

set -x
aws s3 cp --recursive ./ s3://variant-spark/GigaScience/Data/Yggdrasil2/

aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$PEHNO ./
cat $PEHNO | cut -f 2 -d , | tail -n +2 | aws s3 cp - s3://variant-spark/GigaScience/Data/Yggdrasil2/pheno.csv


cat $PEHNO | cut -f 4,5,6,7,8 -d , | datamash transpose -t , > lbl

vname=$(head -n 1 $PEHNO | cut -f 4,5,6,7,8 -d , | sed 's/,/,|/g')
echo $vname

aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$GENO - | pv | bzcat | tail -n +2 | grep -v -E "$vname" | cat lbl - | cut -f 2-1000000000 -d , | pbzip2 -p16 | aws s3 cp - s3://variant-spark/GigaScience/Data/Yggdrasil2/$OUTPUT


aws s3 cp s3://variant-spark/GigaScience/Data/Yggdrasil2/$OUTPUT ./

v=100
for i in {1..17}
do
        set -x
        cat $OUTPUT | pv | pbzip2 -dc -p32 | bash Subset.sh $numSam $v 96
        set +x
        v=$(( v*2 ))
done

exit

