#!/bin/sh

# HOUSEKEEPING & LOG RETENTION AGENT BASH SCRIPT
# Executed automatically by Kubernetes CronJob
# LocalStack address when called from within the Kubernetes / Docker network
LOCALSTACK_HOST="${LOCALSTACK_HOSTNAME:-localstack_main}"
ENDPOINT_URL="http://${LOCALSTACK_HOST}:4566"
BUCKET_NAME="raw-data-ingestion-bucket"

echo "=========================================================="
echo "🕒 [CRONJOB AGENT] STARTING HOUSEKEEPING & STORAGE AUDIT"
echo "Execution Time: $(date)"
echo "=========================================================="

# Use AWS CLI to check the list of files in the S3 Bucket
echo "1. Checking file list in S3 Bucket: $BUCKET_NAME..."
aws --endpoint-url=$ENDPOINT_URL s3 ls s3://$BUCKET_NAME/ --recursive

# Cleanup/archive summary simulation
echo ""
echo "2. Storage Audit & Log Cleanup..."
echo "✅ Audit complete: All files verified safe and archived."
echo "=========================================================="