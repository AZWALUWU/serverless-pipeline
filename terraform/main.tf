# 1. AWS S3 BUCKET (Ingestion Bucket)
# Holds raw CSV/JSON files uploaded by users or APIs
resource "aws_s3_bucket" "ingestion_bucket" {
  bucket        = "raw-data-ingestion-bucket"
  force_destroy = true # Allows bucket deletion during testing even if it contains objects
}

# 2. AWS DYNAMODB TABLE (NoSQL Database)
# Stores aggregated or processed data results from Lambda
resource "aws_dynamodb_table" "processed_data" {
  name         = "processed-data-table"
  billing_mode = "PAY_PER_REQUEST" # Serverless/On-Demand mode with no monthly fixed costs
  hash_key     = "id"              # Unique Primary Key for each item

  # Defines data type for Primary Key 'id'
  attribute {
    name = "id"
    type = "S" # "S" stands for String
  }
}

# 3. AWS SNS TOPIC (Notification/Alerting System)
# Used to dispatch alert messages when data errors or anomalies occur
resource "aws_sns_topic" "anomaly_alerts" {
  name = "anomaly-alerts-topic"
}