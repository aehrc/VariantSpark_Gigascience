#!/bin/bash

# Follow the instruction here: https://github.com/aehrc/VIGWAS/blob/master/Instructions/AWS_Instruction.pdf
# to create an EC2 instance with proper version of VariantSpark installed
# use r4.16xlarge instance and allocage 1000GB EBS volume
# then run this script on that instance.  

numCPU=64
MEM=480g
S3=s3://variant-spark/GigaScience/Data/VSdata/

# add VariantSpark binary to the PATH variable
export PATH=$PATH:/home/ubuntu/VariantSpark/bin/

for numVariant in 10000 100000 1000000 10000000 100000000
do
	if [[ numVariant -eq 10000 ]]
	then
		rate="0.01"
	elif [[ numVariant -eq 100000 ]]; then
		rate="0.001"
	elif [[ numVariant -eq 1000000 ]]; then
		rate="0.0001"
	elif [[ numVariant -eq 10000000 ]]; then
		rate="0.00001"
	elif [[ numVariant -eq 100000000 ]]; then
		rate="0.000001"
	fi

	for numSample in 1000 10000 100000
	do
		echo "========================="
		echo "Variants:	$numVariant"
		echo "Samples:	$numSample"

		size=$((numSample*numVariant))
		seed=$((size/12345))

		prefix=dataset.$numSample.$numVariant

		variant-spark --spark --driver-memory $MEM -- gen-features -sp $numCPU -sr $seed -v -gl  3 -of $prefix.parquet \
		-gs $numSample -gv $numVariant &> $prefix.gen-features.log
		
		aws s3 cp $prefix.parquet $S3$prefix.parquet --recursive
		aws s3 cp $prefix.gen-features.log $S3
		
		variant-spark --spark --driver-memory $MEM -- gen-labels   -sp $numCPU -sr $seed -v -ivo 3 -if $prefix.parquet \
		-fc lable -fcc pheno -ff $prefix.pheno.csv \
		-fiv -gvf $rate -on -onf $prefix.noise.csv -gm 0.5 -gs 0.5 \
		-ge v_$((RANDOM%$numVariant)):1.0 \
		-ge v_$((RANDOM%$numVariant)):1.0 \
		-ge v_$((RANDOM%$numVariant)):1.0 \
		-ge v_$((RANDOM%$numVariant)):1.0 \
		-ge v_$((RANDOM%$numVariant)):1.0 &> $prefix.gen-labels.log

		aws s3 cp $prefix.pheno.csv $S3
		aws s3 cp $prefix.noise.csv $S3
		aws s3 cp $prefix.gen-labels.log $S3

		rm -rf $prefix.parquet
	
	done
done

