#!/bin/bash

#Running on c5.24xlarge AWS EC2 Instance with 96 cpus

g++ -O3 gendata.cpp -o gendata

./gendata 100000 10000 10000 15 123 0.001 sample.csv  | pv | pbzip2 -p95 | aws s3 cp - s3://variant-spark/GigaScience/Data/epic100K100M/s100K.v100M.csv.bz2
bzip2 -p95 sample.csv
aws s3 cp sample.csv.bz2 s3://variant-spark/GigaScience/Data/epic100K100M/
