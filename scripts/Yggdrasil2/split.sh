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



aws s3 cp s3://variant-spark/GigaScience/Data/Yggdrasil2/$OUTPUT - |tee >(bash Subset.sh $numSam 100 1) >(bash Subset.sh $numSam 200 1) >(bash Subset.sh $numSam 400 1) >(bash Subset.sh $numSam 800 1) >(bash Subset.sh $numSam 1600 2) >(bash Subset.sh $numSam 3200 2) >(bash Subset.sh $numSam 6400 2) >(bash Subset.sh $numSam 12800 2) >(bash Subset.sh $numSam 25600 2) >(bash Subset.sh $numSam 51200 2) >(bash Subset.sh $numSam 102400 4) >(bash Subset.sh $numSam 204800 8) >(bash Subset.sh $numSam 409600 8) >(bash Subset.sh $numSam 819200 8) >(bash Subset.sh $numSam 1638400 16) >(bash Subset.sh $numSam 3276800 16) |  bash Subset.sh $numSam 6553600 16

exit

