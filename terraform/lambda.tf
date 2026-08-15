# ------------------------------------------------------------------------------
# 1. IAM ROLE UNTUK LAMBDA
# Menentukan izin akses yang dimiliki oleh Lambda (Formalitas di LocalStack)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 2. OTOMATISASI ZIP KODE PYTHON
# Terraform akan mengompresi isi folder src/lambda menjadi file lambda_function.zip
# ------------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

# ------------------------------------------------------------------------------
# 3. AWS LAMBDA FUNCTION
# Membuat fungsi Lambda di LocalStack
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "data_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "s3-data-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler" # Mengacu pada file index.py dan fungsi handler()
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Variabel Lingkungan (Environment Variables)
  # Memberitahu Lambda nama tabel DynamoDB dan SNS Topic yang sudah kita buat sebelumnya
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.processed_data.name
      SNS_TOPIC_ARN  = aws_sns_topic.anomaly_alerts.arn
    }
  }
}

# ------------------------------------------------------------------------------
# 4. IZIN S3 MEMANGGIL LAMBDA
# Memberikan izin ke S3 Bucket agar boleh mengeksekusi Lambda ini
# ------------------------------------------------------------------------------
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ingestion_bucket.arn
}

# ------------------------------------------------------------------------------
# 5. S3 EVENT TRIGGER
# Memicu Lambda otomatis setiap ada file baru (s3:ObjectCreated:*) yang masuk ke S3
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.ingestion_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.data_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
