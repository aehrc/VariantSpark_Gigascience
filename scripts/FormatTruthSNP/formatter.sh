#!/bin/bash

aws s3 cp s3://variant-spark/GigaScience/Data/PEPS3/ ./ --recursive --exclude "*" --include "*.TruthSNP.csv"

for exp in {1..9}
do
    for run in {1..3}
    do
        fName=$(printf "cnf-%02d-run-%d.TruthSNP.csv" $exp $run)
        vName=$(printf "cnf-%02d-run-%d.TruthSNP.vsis.tsv" $exp $run)
        rName=$(printf "cnf-%02d-run-%d.TruthSNP.lr.tsv" $exp $run)
        cat $fName | tr ':' '_' | sed 's/v/variable/g' > $vName
        cat $fName | tr ':' \\t | awk '{if(NR==1){print("chr\tpos\tref\talt")}else{print()}}' > $rName
    done
done

aws s3 cp ./ s3://variant-spark/GigaScience/Data/PEPS3/ --recursive