# VariantSpark_Gigascience

## Createing an EMR clustr

we use [CreateCluster.sh](scripts/CreateCluster.sh) bash scrtip to create an EMR cluster using aws-cli. Te generated cluster has the following characteristics. **You are responsible to terminate your cluster when once you finish your process**. We have not yet create cloudformation template for this cluster.

- Use Spot pricing
- Use Uniform Instance
- Without EC2 keypair
- Master EC2 instance type: **r4.2xlarge** 8 vCPUs 61GB RAM
- Core EC2 instance type: **r4.4xlarge** 16 vCPUs 122GB RAM

If you would like to change the above configuration (i.e. if you want to use OnDemand pricing or SpotFleet), you may create this cluster and then clone it in the aws console and change the parameter there.

**Parameters:** You should modify the script and manually change these parameter:

- ClusterName: name of the cluster (i.e. C64 or C512)
- InstanceCount: Number of core instances (i.e. 4 or 32)
- LogURI: S3 path where cluster Logs are stored.

**Important**

You should install and configure awscli v2 on your machine (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html). The above bash script uses _aws2_ (awscli v2) to create the EMR cluster. The _aws_ v1 command throw an error on BidPrice.
