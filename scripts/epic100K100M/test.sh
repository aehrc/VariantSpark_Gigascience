#!/bin/bash

g++ -O3 gendata.cpp -o gendata

./gendata 1000 1000 1000 15 123 | pv | pbzip2 -p8 > output.csv.bz2

# too see how fast it is
#./gendata 1000 1000 1000 15 123 | pv | wc -l
