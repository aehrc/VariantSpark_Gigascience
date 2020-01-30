#!/bin/bash

g++ -O3 gendata.cpp -o gendata

./gendata 1000 100 100 15 123 0.05 output.5Percent.csv | pv | pbzip2 -p2 > output.csv.bz2
pbzip2 -p2 output.5Percent.csv

# too see how fast it is
#./gendata 1000 100 100 15 123 0.05 output.5Percent.csv | pv | wc -l
