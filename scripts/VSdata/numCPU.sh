#!/bin/bash

for numInstance in 1 2 4 8 16 32 64
do
    bash stdJOB.sh $numInstance
done
