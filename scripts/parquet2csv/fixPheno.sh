#!/bin/bash

S3=s3://variant-spark/GigaScience/Data/VSdata/

aws s3 cp --recursive $S3 ./ --exclude '*' --include '*pheno.csv'

for numVariant in 10000 100000 1000000 10000000 100000000
do

	for numSample in 1000 10000 100000
	do
		echo "========================="
		echo "Variants:	$numVariant"
		echo "Samples:	$numSample"

		size=$((numSample*numVariant))
		seed=$((size/12345))

		input=dataset.$numSample.$numVariant.pheno.csv
		output=dataset.$numSample.$numVariant.pheno.no_.csv

		cat $input | sed 's/s_/s/g' > $output
	done
done

aws s3 cp --recursive ./ $S3 --exclude '*' --include '*pheno.no_.csv'