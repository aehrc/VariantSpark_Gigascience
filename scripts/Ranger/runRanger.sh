#!/bin/bash

s=$1
numCPU=$2

for v in 100 200 400 800 1600 3200 6400 12800 25600 51200 102400 204800 409600 819200 1638400 3276800 6553600  10000000
do
    set -x
    aws s3 cp s3://variant-spark/GigaScience/Data/Ranger/dataset.s$s.v$v.csv.bz2 - | bzcat > dataset.s$s.v$v.csv 
    
    /usr/bin/time -v  ranger --verbose --file dataset.s$s.v$v.csv --depvarname lable --treetype 1 --ntree 1000 --maxdepth 15 --targetpartitionsize 50 --nthreads $numCPU --outprefix ranger.s$s.v$v 2>&1 | tee ranger.s$s.v$v.log
    
    /usr/bin/time -v  ranger --verbose --file dataset.s$s.v$v.csv --depvarname lable --treetype 1 --ntree 1000 --maxdepth 15 --targetpartitionsize 50 --nthreads $numCPU --outprefix ranger_sm.s$s.v$v --savemem 2>&1 | tee ranger_sm.s$s.v$v.log

    aws s3 cp --recursive --exclude "*" --include "ranger_*.s$s.v$v*" ./ s3://variant-spark/GigaScience/Data/Result_Ranger/

    rm dataset.s$s.v$v.csv
    set +x
done

aws s3 cp --recursive --exclude "*" --include "ranger*" ./ s3://variant-spark/GigaScience/Data/Result_Ranger/

sudo shutdown +1

