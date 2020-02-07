#!/bin/bash

s=$1
v=$2
# head does not work in tee (terminate command) so we use awk
awk -v LN=$v '{if(NR<=LN) print}' | pbzip2 -p$3 > dataset.s$s.v$v.csv.bz2