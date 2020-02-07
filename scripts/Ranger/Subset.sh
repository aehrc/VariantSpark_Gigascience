#!/bin/bash

s=$1
v=$2
cut -f 1-$(( v+1 )) -d , - | pbzip2 -p$3 > dataset.s$s.v$v.csv.bz2