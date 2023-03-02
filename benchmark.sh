#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


PROJECT=$1
JOB_ID_PREFIX=$2  #qbeast-iceberg-integration:europe-southwest1

echo "$PROJECT"
echo "$JOB_ID_PREFIX"

echo -e "${GREEN}Benchmarking Project: ${PROJECT}"

echo -e "${GREEN}Running Warmup Scripts - Starting"

# Warm-up
#find warmup/ -name warmup_*.sql | sort -V | {
#  while read line; do
#    echo "$line"
#    cat "$line" | bq --dataset_id=${PROJECT} \
#      query \
#      --use_legacy_sql=false \
#      --batch=false \
#      --format=none
#  done
#}

echo -e "${GREEN}Running Warmup Scripts - Complete"

# Test
mkdir -p results
echo "Query,Started,Ended,Billing_tier,Bytes_billed,Bytes_processed,Total_slot_timeMs" > results/BigQueryResults.csv

echo -e "${GREEN}Running Benchmark Scripts - Starting"

find query/ -name query*.sql | sort -V | {
  while read -r f; do
    echo "$f"
    QUERY=$(basename "$f" | head -c -5)
    ID=${QUERY}_$(date +%s)


    cat "$f" | bq \
    --dataset_id="$PROJECT" \
    query \
    --use_legacy_sql=false \
    --batch=false \
    --maximum_billing_tier=10 \
    --job_id="$ID" \
    --format=none


    JOB=$(bq --format=json show -j "$JOB_ID_PREFIX"."${ID}")

    echo "$JOB" >> results/"$ID"-stat.json

    STARTED=$(echo "$JOB" | jq .statistics.startTime)
    ENDED=$(echo "$JOB" | jq .statistics.endTime)

    BILLING_TIER=$(echo "$JOB" | jq .statistics.query.billingTier)
    BYTES_BILLED=$(echo "$JOB" | jq .statistics.query.totalBytesBilled)
    BYTES_PROCESSED=$(echo "$JOB" | jq .statistics.totalBytesProcessed)
    TOTAL_SLOT_TIME=$(echo "$JOB" | jq .statistics.totalSlotMs)

    echo "$f,$STARTED,$ENDED,$BILLING_TIER,$BYTES_BILLED,$BYTES_PROCESSED,$TOTAL_SLOT_TIME"
    echo "$f,$STARTED,$ENDED,$BILLING_TIER,$BYTES_BILLED,$BYTES_PROCESSED,$TOTAL_SLOT_TIME" >> results/BigQueryResults.csv
  done
}

echo -e "${GREEN}Running Benchmark Scripts - Complete"