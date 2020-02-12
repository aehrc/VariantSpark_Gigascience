#!/bin/bash

InstanceCount=$1

numCPU=$((InstanceCount*16))
echo "numCPU $numCPU"

sparkParallel=$((numCPU*2))
echo "sparkParallel $sparkParallel"

ClusterName="C$numCPU stdJOB (E7)"
echo "ClusterName $ClusterName"

LogURI=s3n://variant-spark/GigaScience/EMR-LOG/

# Do not change below lines

JSON_FMT='[{"InstanceCount":%s,"BidPrice":"OnDemandPrice","EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":64,"VolumeType":"gp2"},"VolumesPerInstance":4}]},"InstanceGroupType":"CORE","InstanceType":"r4.4xlarge","Name":"Core"},{"InstanceCount":1,"BidPrice":"OnDemandPrice","EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":32,"VolumeType":"gp2"},"VolumesPerInstance":4}]},"InstanceGroupType":"MASTER","InstanceType":"r4.2xlarge","Name":"Master"}]'

InstanceGroups=$(printf "$JSON_FMT" "$InstanceCount")

## only works with aws2. old aws command has some issue parsing the bidPrice
clusterID=$( aws2 emr create-cluster --name "$ClusterName" --log-uri "$LogURI" --applications Name=Spark Name=Ganglia --ec2-attributes '{"InstanceProfile":"EMR_EC2_DefaultRole"}' --release-label emr-5.27.0 --instance-groups $InstanceGroups --configurations '[{"Classification":"spark-defaults","Properties":{"spark.hadoop.io.compression.codecs":"org.apache.hadoop.io.compress.DefaultCodec,is.hail.io.compress.BGzipCodec,org.apache.hadoop.io.compress.GzipCodec","spark.executor.extraClassPath":"/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*:/usr/share/aws/emr/security/conf:/usr/share/aws/emr/security/lib/*:./hail-all-spark.jar","spark.kryo.registrator":"is.hail.kryo.HailKryoRegistrator","spark.driver.extraClassPath":"/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*:/usr/share/aws/emr/security/conf:/usr/share/aws/emr/security/lib/*:/home/hadoop/hail-all-spark.jar","spark.serializer":"org.apache.spark.serializer.KryoSerializer","spark.dynamicAllocation.enabled":"false","spark.jars":"/home/hadoop/hail-all-spark.jar,/home/hadoop/variant-spark-all.jar"}},{"Classification":"spark-env","Properties":{},"Configurations":[{"Classification":"export","Properties":{"PYSPARK_PYTHON":"/usr/bin/python3","PYSPARK_DRIVER_PYTHON":"${PYSPARK_DRIVER_PYTHON:-/home/hadoop/biospark/bin/python}","PYSPARK_DRIVER_PYTHON_OPTS":"${PYSPARK_DRIVER_PYTHON_OPTS:-}"}}]},{"Classification":"spark","Properties":{"maximizeResourceAllocation":"true"}}]' --auto-terminate --auto-scaling-role EMR_AutoScaling_DefaultRole --bootstrap-actions '[{"Path":"s3://variant-spark/GigaScience/biospark/1.0.1/bootstrap/install-biospark.sh","Args":["--biospark-url","s3://variant-spark/GigaScience/biospark/1.0.1"],"Name":"Install Biospark"}]' --ebs-root-volume-size 32 --service-role EMR_DefaultRole --enable-debugging --scale-down-behavior TERMINATE_AT_TASK_COMPLETION | grep 'ClusterId' | awk '{print($2)}' | tr -d '"' | tr -d ',')

echo "clusterID $clusterID"

MEM=60g
S3=s3://variant-spark/GigaScience/Data/VSdata/
S3R=s3://variant-spark/GigaScience/Data/Results/

################################
##### E7: The Effect of numCPU
################################
experiment="E7"
numTree=1000
mtryFraction="0.1"
maxDepth=15
minSample=50
batchSize=100
numVariant=1000000
numSample=10000

#do
	echo "========================="

	size=$((numSample*numVariant))
	seed=$((numCPU* 123456))
	echo "seed: " $seed


	prefix=dataset.$numSample.$numVariant
	prefixOut=$(printf "$experiment.cpu%04d" $numCPU)
	echo "output: " $prefixOut
	echo "-------------------------"

	JSON_FMT='[{"Args":["spark-submit","--deploy-mode","client","--class","au.csiro.variantspark.cli.VariantSparkApp","/home/hadoop/biospark/lib/python3.6/site-packages/varspark/jars/variant-spark_2.11-0.3.0-SNAPSHOT-all.jar","importance","-io","{\\"defVariableType\\":\\"ORDINAL(3)\\"}","-sp","%s","-sr","%s","-v","-ro","-rn","%s","-rbs","%s","-rmtf","%s","-it","csv","-if","%s","-fc","lable","-ff","%s","-of","%s","-on","1000000","-om","%s","-omf","json","-rmns","%s","-rmd","%s"],"Type":"CUSTOM_JAR","ActionOnFailure":"CONTINUE","Jar":"command-runner.jar","Properties":"","Name":"%s"}]'

	step=$(printf "$JSON_FMT" "$sparkParallel" "$seed" "$numTree" "$batchSize" "$mtryFraction" "$S3$prefix.csv.bz2" "$S3$prefix.pheno.no_.csv" "$S3R$prefixOut.vsis.csv" "$S3R$prefixOut.rf.json" "$minSample" "$maxDepth" "$prefixOut")

	echo $step
	echo "-------------------------"

	aws2 emr add-steps --cluster-id $clusterID --steps $step

#done