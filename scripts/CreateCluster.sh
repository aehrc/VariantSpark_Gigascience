ClusterName="C32 bioSpark v1.0.1" #options: C32, C64, C128, C256, C512, C1024
InstanceCount="2"                 #options: 2  , 4  , 8   , 16  , 32  , 64    # Each instance count as 16 CPU
LogURI=s3n://variant-spark/GigaScience/EMR-LOG/

# Do not change below lines

JSON_FMT='[{"InstanceCount":%s,"BidPrice":"OnDemandPrice","EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":64,"VolumeType":"gp2"},"VolumesPerInstance":4}]},"InstanceGroupType":"CORE","InstanceType":"r4.4xlarge","Name":"Core"},{"InstanceCount":1,"BidPrice":"OnDemandPrice","EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":32,"VolumeType":"gp2"},"VolumesPerInstance":4}]},"InstanceGroupType":"MASTER","InstanceType":"r4.2xlarge","Name":"Master"}]'

InstanceGroups=$(printf "$JSON_FMT" "$InstanceCount")

## only works with aws2. old aws command has some issue parsing the bidPrice
aws2 emr create-cluster --name "$ClusterName" --log-uri "$LogURI" --applications Name=Spark Name=Ganglia --ec2-attributes '{"InstanceProfile":"EMR_EC2_DefaultRole"}' --release-label emr-5.27.0 --instance-groups $InstanceGroups --configurations '[{"Classification":"spark-defaults","Properties":{"spark.hadoop.io.compression.codecs":"org.apache.hadoop.io.compress.DefaultCodec,is.hail.io.compress.BGzipCodec,org.apache.hadoop.io.compress.GzipCodec","spark.executor.extraClassPath":"/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*:/usr/share/aws/emr/security/conf:/usr/share/aws/emr/security/lib/*:./hail-all-spark.jar","spark.kryo.registrator":"is.hail.kryo.HailKryoRegistrator","spark.driver.extraClassPath":"/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*:/usr/share/aws/emr/security/conf:/usr/share/aws/emr/security/lib/*:/home/hadoop/hail-all-spark.jar","spark.serializer":"org.apache.spark.serializer.KryoSerializer","spark.dynamicAllocation.enabled":"false","spark.jars":"/home/hadoop/hail-all-spark.jar,/home/hadoop/variant-spark-all.jar"}},{"Classification":"spark-env","Properties":{},"Configurations":[{"Classification":"export","Properties":{"PYSPARK_PYTHON":"/usr/bin/python3","PYSPARK_DRIVER_PYTHON":"${PYSPARK_DRIVER_PYTHON:-/home/hadoop/biospark/bin/python}","PYSPARK_DRIVER_PYTHON_OPTS":"${PYSPARK_DRIVER_PYTHON_OPTS:-}"}}]},{"Classification":"spark","Properties":{"maximizeResourceAllocation":"true"}}]' --auto-scaling-role EMR_AutoScaling_DefaultRole --bootstrap-actions '[{"Path":"s3://variant-spark/GigaScience/biospark/1.0.1/bootstrap/install-biospark.sh","Args":["--biospark-url","s3://variant-spark/GigaScience/biospark/1.0.1"],"Name":"Install Biospark"}]' --ebs-root-volume-size 32 --service-role EMR_DefaultRole --enable-debugging --scale-down-behavior TERMINATE_AT_TASK_COMPLETION 