#!/bin/bash

# Create a C256 EMR Cluster and copy the cluster ID below
clusterID="j-25AOLS8FZJU5N"

sparkParallel=512
MEM=60g
GENO=s3://variant-spark/GigaScience/Data/1000Genomes/
PHENO=s3://variant-spark/GigaScience/Data/PEPS3/
RES=s3://variant-spark/GigaScience/Data/GSVS1000Genome/


################################
##### E13: GSVS1000Genome
################################
experiment="E13"
numTree=1000
mtryFraction="0.1"
maxDepth=15
minSample=50
batchSize=100

for subset in '3.withTruth' '3' '2.withTruth' '2'
do
	for run in 1 2 3
	do
		for exp in 2 5 8 1 4 7 3 6 9
		do
			echo "========================="

			seed=$((exp*run*13))
			echo "seed: " $seed

			stepName=$(printf "cnf-%02d-run-%d" $exp $run)
			echo $stepName

			fgeno=$GENO'subset.'$subset'.vcf.bgz'
			fpheno=$PHENO$stepName".pheno.csv"
			fout=$RES$experiment'.'$subset'.'$stepName
			echo "geno: " $fgeno
			echo "pheno: " $fpheno
			echo "output: " $fout
			echo "-------------------------"

			JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","vcf","-if","%s","-fc","lbl","-ff","%s","-of","%s","-on","100000000","-om","%s","-omf","json","-rmns","%s","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

			step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$fgeno" "$fpheno" "$fout.vsis.csv" "$fout.rf.json" "$minSample" "$maxDepth" "$stepName")

			echo $step
			echo "-------------------------"

			aws2 emr add-steps --cluster-id $clusterID --steps $step

		done
	done
done

for subset in '0'
do
	for run in 1
	do
		for exp in 2 5 8 1 4 7 3 6 9
		do
			echo "========================="

			seed=$((exp*run*13))
			echo "seed: " $seed

			stepName=$(printf "cnf-%02d-run-%d" $exp $run)
			echo $stepName

			fgeno=$GENO'subset.'$subset'.vcf.bgz'
			fpheno=$PHENO$stepName".pheno.csv"
			fout=$RES'out.'$subset'.'$stepName
			echo "geno: " $fgeno
			echo "pheno: " $fpheno
			echo "output: " $fout
			echo "-------------------------"

			JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","vcf","-if","%s","-fc","lbl","-ff","%s","-of","%s","-on","100000000","-om","%s","-omf","json","-rmns","%s","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

			step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$fgeno" "$fpheno" "$fout.vsis.csv" "$fout.rf.json" "$minSample" "$maxDepth" "$stepName")

			echo $step
			echo "-------------------------"

			aws2 emr add-steps --cluster-id $clusterID --steps $step

		done
	done
done