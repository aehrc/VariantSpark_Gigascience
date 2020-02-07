
#!/bin/bash

aws s3 cp --recursive ./ s3://variant-spark/GigaScience/Data/ReForeSt/
s=10000
for v in 100 200 400 800 1600 3200 6400 12800 25600 51200 102400 204800 409600 819200 1638400 3276800 6553600
    aws s3 cp s3://variant-spark/GigaScience/Data/Ranger/dataset.s$s.v$v.csv.bz2 - | pv | bzcat | tail -n 2+ | python csv2libsvmPipe.py | pbzip2 -p64 | aws s3 cp - s3://variant-spark/GigaScience/Data/ReForeSt/dataset.s$s.v$v.libsvm.bz2