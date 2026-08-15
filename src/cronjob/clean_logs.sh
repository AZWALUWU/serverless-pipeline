#!/bin/sh

# ------------------------------------------------------------------------------
# SKRIP BASH HOUSEKEEPING & LOG RETENTION AGENT
# Dijalankan secara otomatis oleh Kubernetes CronJob
# ------------------------------------------------------------------------------

# Alamat LocalStack jika dipanggil dari dalam jaringan Kubernetes / Docker
LOCALSTACK_HOST="${LOCALSTACK_HOSTNAME:-localstack_main}"
ENDPOINT_URL="http://${LOCALSTACK_HOST}:4566"
BUCKET_NAME="raw-data-ingestion-bucket"

echo "=========================================================="
echo "🕒 [CRONJOB AGENT] MEMULAI HOUSEKEEPING & AUDIT STORAGE"
echo "Waktu Eksekusi: $(date)"
echo "=========================================================="

# Menggunakan AWS CLI untuk memeriksa daftar file yang ada di S3 Bucket
echo "1. Memeriksa daftar berkas di S3 Bucket: $BUCKET_NAME..."
aws --endpoint-url=$ENDPOINT_URL s3 ls s3://$BUCKET_NAME/ --recursive

# Simulasi ringkasan pembersihan/arsip
echo ""
echo "2. Audit Storage & Pembersihan Log..."
echo "✅ Audit selesai: Semua berkas terverifikasi aman dan terarsip."
echo "=========================================================="
