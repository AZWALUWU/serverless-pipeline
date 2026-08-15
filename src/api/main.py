import os
import boto3
from fastapi import FastAPI, File, UploadFile, HTTPException, status

app = FastAPI(
    title="Serverless Data Ingestion API",
    description="API Service for uploading data files to AWS S3 Ingestion Bucket",
    version="1.0.0"
)


# AWS S3 CLIENT CONFIGURATION (LOCALSTACK)

S3_BUCKET_NAME = os.environ.get("S3_BUCKET_NAME", "raw-data-ingestion-bucket")
LOCALSTACK_HOST = os.environ.get("LOCALSTACK_HOSTNAME", "localhost")
ENDPOINT_URL = f"http://{LOCALSTACK_HOST}:4566"

# Initialize S3 Client pointing to LocalStack
s3_client = boto3.client(
    "s3",
    endpoint_url=ENDPOINT_URL,
    aws_access_key_id="test",
    aws_secret_access_key="test",
    region_name="us-east-1"
)

@app.get("/")
def root():
    """API Health Check Endpoint"""
    return {
        "status": "online",
        "service": "Upload Ingestion API",
        "target_bucket": S3_BUCKET_NAME
    }

@app.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_file(file: UploadFile = File(...)):
    """
    Endpoint for uploading files (CSV / JSON) to AWS S3.
    """
    # 1. Validate File Extension
    allowed_extensions = [".csv", ".json"]
    file_ext = os.path.splitext(file.filename)[1].lower()
    
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File format '{file_ext}' is not supported! Please use .csv or .json"
        )

    try:
        # 2. Upload File Directly to AWS S3
        print(f"Uploading file '{file.filename}' to S3 Bucket '{S3_BUCKET_NAME}'...")
        
        s3_client.upload_fileobj(
            file.file,
            S3_BUCKET_NAME,
            file.filename
        )

        return {
            "message": "File uploaded successfully!",
            "file_name": file.filename,
            "target_bucket": S3_BUCKET_NAME,
            "status": "SUCCESS"
        }

    except Exception as e:
        print(f"Error while uploading to S3: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload file to S3: {str(e)}"
        )