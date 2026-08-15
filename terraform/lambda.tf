# 1. IAM ROLE FOR LAMBDA
# Defines access permissions held by Lambda (Formality in LocalStack)
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

# 2. PYTHON CODE ZIP AUTOMATION
# Terraform compresses the contents of src/lambda directory into lambda_function.zip

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

# 3. AWS LAMBDA FUNCTION
# Creates the Lambda function in LocalStack

resource "aws_lambda_function" "data_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "s3-data-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler" # Refers to index.py file and handler() function
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Environment Variables
  # Passes the DynamoDB table name and SNS Topic ARN created previously to Lambda
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.processed_data.name
      SNS_TOPIC_ARN  = aws_sns_topic.anomaly_alerts.arn
    }
  }
}

# 4. S3 PERMISSION TO INVOKE LAMBDA
# Grants permission to the S3 Bucket to execute this Lambda function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ingestion_bucket.arn
}

# 5. S3 EVENT TRIGGER
# Automatically triggers Lambda whenever a new file (s3:ObjectCreated:*) arrives in S3
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.ingestion_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.data_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}