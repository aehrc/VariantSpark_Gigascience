#!/bin/bash

s=$1
v=$2

set -x
cat - | head -n $(( v+1 )) | pbzip2 -p$3 | aws s3 cp - s3://variant-spark/GigaScience/Data/Yggdrasil2/dataset.s$s.v$v.csv.bz2