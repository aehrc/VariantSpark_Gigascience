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
cut -f 2,4,5,6,7,8 -d , $PEHNO > lbl
cat $GENO | pv | bzcat | grep -v -E "$vname" | split -a 10 -l $LINES
set +x

echo "Number of lines in each files"
wc -l x*

echo "Number of files"
ls x* | wc -l

echo "Transpose each part"
ls -1 x* | xargs -n 1 -P 8 -I % sh -c 'echo %;  datamash transpose -t , < % > %.t; rm %'

set -x

paste x*.t | tr \\t , | cut -f 2-1000000000 -d , | paste lbl - | tr \\t , | pbzip2 -p16 > $OUTPUT
rm lbl x*

aws s3 cp $OUTPUT s3://variant-spark/GigaScience/Data/Ranger/

bzcat $OUTPUT | tee >(bash Subset.sh $numSam 100 1) >(bash Subset.sh $numSam 200 1) >(bash Subset.sh $numSam 400 1) >(bash Subset.sh $numSam 800 1) >(bash Subset.sh $numSam 1600 2) >(bash Subset.sh $numSam 3200 2) >(bash Subset.sh $numSam 6400 2) >(bash Subset.sh $numSam 12800 2) >(bash Subset.sh $numSam 25600 2) >(bash Subset.sh $numSam 51200 2) >(bash Subset.sh $numSam 102400 4) >(bash Subset.sh $numSam 204800 4) >(bash Subset.sh $numSam 409600 4) >(bash Subset.sh $numSam 819200 8)  |  bash Subset.sh $numSam 1638400 16

aws s3 cp --recursive ./ s3://variant-spark/GigaScience/Data/Ranger/

# /usr/bin/time -v  ranger --verbose --file $4 --depvarname lable --treetype 1 --ntree 100 --nthreads 8 --outprefix ranger.out 2>&1 | tee ranger.log
# /usr/bin/time -v  ranger --verbose --file $4 --depvarname lable --treetype 1 --ntree 100 --nthreads 8 --outprefix ranger.sm.out --savemem 2>&1 | tee ranger.sm.log

exit

