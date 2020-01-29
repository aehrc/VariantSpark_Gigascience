#!/bin/bash

# Create a C256 EMR Cluster and copy the cluster ID below
clusterID="j-XXXXXXXXXXXXX"

sparkParallel=512
MEM=60g
S3=s3://variant-spark/GigaScience/Data/VSdata/
S3R=s3://variant-spark/GigaScience/Data/VSdataResult/

################################
##### E0: pretty default
################################
experiment="E0"
numTree=1000
mtryFraction="0.1"
#maxDepth=NA
#minSample=NA
batchSize=100
numVariant=1000000
numSample=10000

# for nothing
# do
	echo "========================="
	echo "Variants:	$numVariant"
	echo "Samples:	$numSample"

	size=$((numSample*numVariant))
	seed=$((maxDepth*123))


	prefix=dataset.$numSample.$numVariant
	prefixOut=$experiment

	JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\"defVariableType\":\"ORDINAL(3)\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

	step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$S3$prefix.csv.bz2" "$S3$prefix.pheno.no_.csv" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$prefixOut")

	echo $step

	aws emr add-steps --cluster-id $clusterID --steps $step

# done

################################
##### E1: The Effect of maxDepth
################################
experiment="E1"
numTree=1000
mtryFraction="0.1"
#maxDepth=X
#minSample=NA
batchSize=100
numVariant=1000000
numSample=10000

for maxDepth in 3 5 7 9 11 13 15 20 25 100
do
	echo "========================="
	echo "Variants:	$numVariant"
	echo "Samples:	$numSample"

	size=$((numSample*numVariant))
	seed=$((maxDepth*123))


	prefix=dataset.$numSample.$numVariant
	prefixOut=$experiment.md$maxDepth

	JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\"defVariableType\":\"ORDINAL(3)\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

	step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$S3$prefix.csv.bz2" "$S3$prefix.pheno.no_.csv" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$maxDepth" "$prefixOut")

	echo $step

	aws emr add-steps --cluster-id $clusterID --steps $step

done

################################
##### E2: The Effet of minimum number of samples in a node to be splited
################################
experiment="E2"
numTree=1000
mtryFraction="0.1"
#maxDepth=NA
#minSample=X
batchSize=100
numVariant=1000000
numSample=10000

for minSample in 5 10  50 100 500 1000
do
	echo "========================="
	echo "Variants:	$numVariant"
	echo "Samples:	$numSample"

	size=$((numSample*numVariant))
	seed=$((minSample*321))


	prefix=dataset.$numSample.$numVariant
	prefixOut=$experiment.ms$minSample

	JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\"defVariableType\":\"ORDINAL(3)\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json","-rmns","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

	step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$S3$prefix.csv.bz2" "$S3$prefix.pheno.no_.csv" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$minSample" "$prefixOut")

	echo $step

	aws emr add-steps --cluster-id $clusterID --steps $step

done

################################
##### E3: The Effect of numTree
################################
experiment="E3"
#numTree=X
mtryFraction="0.1"
maxDepth=15
minSample=50
batchSize=100
numVariant=1000000
numSample=10000

for numTree in 100 200 400 800 1600
do
	echo "========================="
	echo "Variants:	$numVariant"
	echo "Samples:	$numSample"

	size=$((numSample*numVariant))
	seed=$((ntree*13))


	prefix=dataset.$numSample.$numVariant
	prefixOut=$experiment.nt$numTree

	JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\"defVariableType\":\"ORDINAL(3)\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json","-rmns","%s","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

	step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$S3$prefix.csv.bz2" "$S3$prefix.pheno.no_.csv" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$minSample" "$maxDepth" "$prefixOut")

	echo $step

	aws emr add-steps --cluster-id $clusterID --steps $step

done

################################
##### E4: The Effect of batchSize
################################
experiment="E4"
numTree=1000
mtryFraction="0.1"
maxDepth=15
minSample=50
#batchSize=X
numVariant=1000000
numSample=10000

for batchSize in 10 50 100 500 1000
do
	echo "========================="
	echo "Variants:	$numVariant"
	echo "Samples:	$numSample"

	size=$((numSample*numVariant))
	seed=$((batchSize*7))


	prefix=dataset.$numSample.$numVariant
	prefixOut=$experiment.bs$batchSize

	JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\"defVariableType\":\"ORDINAL(3)\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json","-rmns","%s","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

	step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$S3$prefix.csv.bz2" "$S3$prefix.pheno.no_.csv" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$minSample" "$maxDepth" "$prefixOut")

	echo $step

	aws emr add-steps --cluster-id $clusterID --steps $step

done

################################
##### E5: The Effect of mtry
################################
experiment="E5"
numTree=1000
#mtry=X
maxDepth=15
minSample=50
batchSize=100
numVariant=1000000
numSample=10000

for mtry in 10000 5000 1000 500 100 50 10
do
	echo "========================="
	echo "Variants:	$numVariant"
	echo "Samples:	$numSample"

	size=$((numSample*numVariant))
	seed=$((mtry*21))


	prefix=dataset.$numSample.$numVariant
	prefixOut=$experiment.mt$mtry

	JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\"defVariableType\":\"ORDINAL(3)\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmt","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json","-rmns","%s","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

	step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtry" "$S3$prefix.csv.bz2" "$S3$prefix.pheno.no_.csv" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$minSample" "$maxDepth" "$prefixOut")

	echo $step

	aws emr add-steps --cluster-id $clusterID --steps $step

done

################################
##### E6: The Effect of numSamples and Variants. (The 3 Biggest datasets are not processed)
################################
experiment="E6"
numTree=1000 # reduce to 100 for larger datasets
mtryFraction="0.1"
maxDepth=15
minSample=50
batchSize=100
#numVariant=X
#numSample=Y

for numVariant in 10000 100000 1000000 10000000 100000000
do

	for numSample in 1000 10000 100000
	do
		echo "========================="
		echo "Variants:	$numVariant"
		echo "Samples:	$numSample"

		size=$((numSample*numVariant))
		seed=$((size/12345))

		if [[ numSample -gt 10000 ]]
		then
			echo "10 batch"
			batchSize=10
		fi

		if [[ size -gt 10000000000 ]]
		then
			echo "100 Trees"
			numTree=100
		fi

		if [[ size -gt 1000000000000 ]]
		then
			echo "Dataset is too big"
		else
			prefix=dataset.$numSample.$numVariant
			prefixOut=$experiment.s$numSample.v$numVariant.nt$numTree.bs$batchSize

		JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\"defVariableType\":\"ORDINAL(3)\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json","-rmns","%s","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

		step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$S3$prefix.csv.bz2" "$S3$prefix.pheno.no_.csv" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$minSample" "$maxDepth" "$prefixOut")

			echo $step

			aws emr add-steps --cluster-id $clusterID --steps $step
		fi

	done
done



