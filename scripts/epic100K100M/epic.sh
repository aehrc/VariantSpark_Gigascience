#!/bin/bash

g++ -O3 gendata.cpp -o gendata

awk 'BEGIN{print("s,label"); for(i=0; i<100000; i++){print("s_"i","int(2*rand()));}}' | aws s3 cp - s3://variant-spark/GigaScience/Data/SuppData/Datasets/100K-100M/pheno.csv

for i in {0..100}
do
	echo $i
	set -x
	./gendata 100000 1000 1000 15 $RANDOM 0.001 f$i.csv $i | pv | pbzip2 -p45 | aws s3 cp - s3://variant-spark/GigaScience/Data/SuppData/Datasets/100K-100M/genotype.csv.bz2/d$i.csv.bz2
	pbzip2 -p45 f$i.csv
	aws s3 cp f$i.csv.bz2 s3://variant-spark/GigaScience/Data/SuppData/Datasets/100K-100M/fraction/
	rm f$i.csv.bz2
	set +x
done

#CID=$(bash CreateCluster.sh | grep 'Id' | cut -f 2 -d ':' | tr -d '"' | tr -d ' ' | tr -d ',')

#/usr/local/bin/aws emr add-steps --cluster-id $CID --steps '[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\"defVariableType\":\"ORDINAL(3)\"}","-sp","4096","-sr","13","-v","-ro","-rn","10","-rbs","10","-rmtf","0.1","-it","csv","-if","s3://variant-spark/GigaScience/Data/SuppData/Datasets/100K-100M/genotype.csv.bz2","-fc","label","-ff","s3://variant-spark/GigaScience/Data/SuppData/Datasets/100K-100M/pheno.csv","-of","s3://variant-spark/GigaScience/Data/SuppData/Datasets/100K-100M/output.vsis.csv","-on","1000000","-om","s3://variant-spark/GigaScience/Data/SuppData/Datasets/100K-100M/output.rf.json","-omf","json","-rmns","50","-rmd","15"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"Test"}]'
