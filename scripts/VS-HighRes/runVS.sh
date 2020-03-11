#!/bin/bash

# Create a C256 EMR Cluster and copy the cluster ID below
clusterID="j-1Q5ON0IGIDKCD"

sparkParallel=512
MEM=60g
S3=s3://variant-spark/GigaScience/Data/vs-highRes/
S3R=s3://variant-spark/GigaScience/Data/vs-highRes/Results/
Pheno=s3://variant-spark/GigaScience/Data/vs-highRes/pheno.csv


################################
##### E10: The Effect of numTree
################################
experiment="E10"
numTree=1000
mtryFraction="0.1"
maxDepth=15
minSample=50
batchSize=100
numVariant=100
numSample=10000

for numVariant in 100 200 400 800 1600 3200 6400 12800 25600 51200 102400 204800 409600 819200 1638400 3276800 6553600 10000000
do
	echo "========================="

	size=$((numSample*numVariant))
	seed=$((numVariant*1313))
	echo "seed: " $seed


	prefix=dataset.s$numSample.v$numVariant
	prefixOut=$(printf "$experiment.v%08d" $numVariant)
	echo "output: " $prefixOut
	echo "-------------------------"

	JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\\"defVariableType\\":\\"ORDINAL(3)\\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json","-rmns","%s","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

	step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$S3$prefix.csv.bz2" "$Pheno" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$minSample" "$maxDepth" "$prefixOut")

	echo $step
	echo "-------------------------"

	aws2 emr add-steps --cluster-id $clusterID --steps $step

done