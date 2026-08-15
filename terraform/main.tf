# ------------------------------------------------------------------------------
# 1. AWS S3 BUCKET (Ingestion Bucket)
# Tempat menampung file CSV/JSON mentah yang diunggah oleh pengguna/API
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "ingestion_bucket" {
  bucket        = "raw-data-ingestion-bucket"
  force_destroy = true # Memungkinkan bucket dihapus saat pengujian walaupun ada isinya
}

# ------------------------------------------------------------------------------
# 2. AWS DYNAMODB TABLE (Database NoSQL)
# Tempat menyimpan hasil agregasi/olahan data dari Lambda
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "processed_data" {
  name         = "processed-data-table"
  billing_mode = "PAY_PER_REQUEST" # Mode tanpa biaya bulanan (Serverless/On-Demand)
  hash_key     = "id"              # Primary Key unik untuk setiap data

  # Mendefinisikan tipe data untuk Primary Key 'id'
  attribute {
    name = "id"
    type = "S" # "S" berarti String (Teks)
  }
}

# ------------------------------------------------------------------------------
# 3. AWS SNS TOPIC (Notification/Alerting System)
# Tempat mengirim pesan peringatan jika terjadi error/anomali data
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "anomaly_alerts" {
  name = "anomaly-alerts-topic"
}
