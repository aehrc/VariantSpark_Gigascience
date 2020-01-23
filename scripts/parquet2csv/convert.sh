set -ex

BUCKET_PREFIX=s3://variant-spark/GigaScience/Data/VSdata/
BASE_NAME=dataset.${1}.${2}
PARQUET_DIR=${BASE_NAME}.parquet
PARQUET_TOOLS=parquet-mr/parquet-tools/target/parquet-tools-1.12.0-SNAPSHOT.jar
MERGED_FILE=${BASE_NAME}.merged
OUTPUT=${BASE_NAME}.csv.bz2

aws s3 cp ${BUCKET_PREFIX}${PARQUET_DIR} ${PARQUET_DIR} --recursive
java -jar ${PARQUET_TOOLS} merge ${PARQUET_DIR} ${MERGED_FILE}
rm -rf ${PARQUET_DIR}
java -jar ${PARQUET_TOOLS} cat ${MERGED_FILE} | ./convert ${1} | lbzip2 -n 20 > ${OUTPUT}
aws s3 cp ${OUTPUT} ${BUCKET_PREFIX}
rm ${MERGED_FILE} ${OUTPUT}

