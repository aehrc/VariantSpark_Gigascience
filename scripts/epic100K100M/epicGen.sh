#!/bin/bash

g++ -O3 gendata.cpp -o gendata

./gendata 100000 10000 10000 15 123 | pv | pbzip2 -p$1 | aws s3 cp - $2

