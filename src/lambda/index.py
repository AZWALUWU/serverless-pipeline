import json
import os
import urllib.parse
import boto3
import csv
import io
import uuid
from datetime import datetime


# BOTO3 CONFIGURATION (AWS SDK FOR PYTHON)
# Fetch environment variables from Terraform and LocalStack

DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "processed-data-table")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

# Configure LocalStack endpoint for containerized Lambda communication with local AWS services
localstack_host = os.environ.get("LOCALSTACK_HOSTNAME", "localhost")
endpoint_url = f"http://{localstack_host}:4566"

s3_client = boto3.client("s3", endpoint_url=endpoint_url)
dynamodb_resource = boto3.resource("dynamodb", endpoint_url=endpoint_url)
sns_client = boto3.client("sns", endpoint_url=endpoint_url)

table = dynamodb_resource.Table(DYNAMODB_TABLE_NAME)


def handler(event, context):
    """
    Main Lambda Handler Function
    Triggered automatically on s3:ObjectCreated events
    """
    print("=== [LAMBDA PROCESSOR] STARTING FILE PROCESSING ===")

    try:
        # 1. Extract Bucket Name and File Name (Key) from S3 Event
        record = event["Records"][0]
        bucket_name = record["s3"]["bucket"]["name"]
        # unquote_plus converts URL-encoded characters (e.g., %20 to space)
        file_key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        print(f"File found: '{file_key}' in Bucket: '{bucket_name}'")

        # 2. Download File from S3
        s3_response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
        file_content = s3_response["Body"].read().decode("utf-8")

        # 3. Process/Parse File Contents based on Format (JSON or CSV)
        total_items = 0
        total_amount = 0.0
        anomalies_found = []

        if file_key.endswith(".json"):
            data = json.loads(file_content)
            # Handle list of transaction items or single object
            items = data if isinstance(data, list) else [data]
            
            for index, item in enumerate(items):
                total_items += 1
                amount = float(item.get("amount", 0))
                total_amount += amount

                # Anomaly Detection: Negative transaction values
                if amount < 0:
                    anomalies_found.append(
                        f"Row {index + 1}: Negative transaction value (${amount})"
                    )

        elif file_key.endswith(".csv"):
            csv_reader = csv.DictReader(io.StringIO(file_content))
            for index, row in enumerate(csv_reader):
                total_items += 1
                amount = float(row.get("amount", 0))
                total_amount += amount

                # Anomaly Detection: Negative transaction values
                if amount < 0:
                    anomalies_found.append(
                        f"Row {index + 1}: Negative transaction value (${amount})"
                    )

        # 4. Save Processed Results to DynamoDB
        record_id = str(uuid.uuid4())
        processed_at = datetime.utcnow().isoformat()

        table.put_item(
            Item={
                "id": record_id,
                "file_name": file_key,
                "total_records": total_items,
                "total_amount": str(round(total_amount, 2)),
                "has_anomaly": len(anomalies_found) > 0,
                "anomaly_count": len(anomalies_found),
                "processed_at": processed_at,
            }
        )
        print(f"✅ Data successfully saved to DynamoDB with ID: {record_id}")

        # 5. Send AWS SNS Notification if Anomalies Detected
        if anomalies_found and SNS_TOPIC_ARN:
            alert_message = (
                f"🚨 DATA ANOMALY ALARM DETECTED 🚨\n\n"
                f"File Name: {file_key}\n"
                f"Total Records: {total_items}\n"
                f"Anomaly Count: {len(anomalies_found)}\n"
                f"Anomaly Details:\n" + "\n".join(anomalies_found)
            )

            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"Alert: Data Anomaly in File {file_key}",
                Message=alert_message,
            )
            print("⚠️ Alert notification successfully sent to AWS SNS!")

        return {
            "statusCode": 200,
            "body": json.dumps({"status": "SUCCESS", "record_id": record_id}),
        }

    except Exception as e:
        print(f"❌ Error while processing file: {str(e)}")
        raise e