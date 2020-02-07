#!/bin/bash

set -x
for numVar in 10000 100000 1000000
do
	for numSam in 1000 10000
    do
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>"
        echo $numSam.$numVar
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>"
        PEHNO=dataset.$numSam.$numVar.pheno.no_.csv # phenotype file
        GENO=dataset.$numSam.$numVar.csv.bz2  # genotype file

        OUT_GENO=dataset.s$numSam.v$numVar.csv.bz2
        OUT_PHENO=dataset.s$numSam.v$numVar.pheno.csv

        aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$PEHNO ./
        aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$GENO ./

        cut -f 2 -d , $PEHNO | tail -n +2 > $OUT_PHENO
        cat $GENO | pv | bzcat | tail -n +2 | cut -f 2-1000000000 -d , | pbzip2 -p16 > $OUT_GENO

        aws s3 cp $OUT_GENO s3://variant-spark/GigaScience/Data/Yggdrasil/
        aws s3 cp $OUT_PHENO s3://variant-spark/GigaScience/Data/Yggdrasil/

        rm $GENO $PEHNO $OUT_PHENO $OUT_GENO
    done
done


for numVar in 10000000 100000000
do
	for numSam in 1000 10000
    do
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>"
        echo $numSam.$numVar
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>"
        PEHNO=dataset.$numSam.$numVar.pheno.no_.csv # phenotype file
        GENO=dataset.$numSam.$numVar.csv.bz2  # genotype file

        OUT_GENO=dataset.s$numSam.v$numVar.csv.bz2
        OUT_PHENO=dataset.s$numSam.v$numVar.pheno.csv

        aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$PEHNO ./
        aws s3 cp s3://variant-spark/GigaScience/Data/VSdata/$GENO ./

        cut -f 2 -d , $PEHNO | tail -n +2 > $OUT_PHENO
        cat $GENO | pv | bzcat | tail -n +2 | cut -f 2-1000000000 -d , | pbzip2 -p16 > $OUT_GENO

        aws s3 cp $OUT_GENO s3://variant-spark/GigaScience/Data/Yggdrasil/
        aws s3 cp $OUT_PHENO s3://variant-spark/GigaScience/Data/Yggdrasil/

        rm $GENO $PEHNO $OUT_PHENO $OUT_GENO
    done
done
exit

