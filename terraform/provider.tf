terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # Menggunakan kunci akses dummy/palsu karena ini berjalan di LocalStack
  access_key = "test"
  secret_key = "test"

  # Melewati validasi kredensial resmi AWS
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  s3_use_path_style = true
  # MENGARAHKAN SEMUA PERMINTAAN KE LOCALSTACK (PORT 4566)
  endpoints {
    s3       = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sns      = "http://localhost:4566"
    iam      = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}
