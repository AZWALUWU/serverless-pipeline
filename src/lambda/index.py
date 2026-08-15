import json
import os
import urllib.parse
import boto3
import csv
import io
import uuid
from datetime import datetime

# ------------------------------------------------------------------------------
# KONFIGURASI BOTO3 (AWS SDK FOR PYTHON)
# Mengambil variabel lingkungan dari Terraform dan LocalStack
# ------------------------------------------------------------------------------
DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "processed-data-table")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

# Mengatur endpoint LocalStack agar Lambda dalam container bisa berkomunikasi dengan layanan AWS lokal
localstack_host = os.environ.get("LOCALSTACK_HOSTNAME", "localhost")
endpoint_url = f"http://{localstack_host}:4566"

s3_client = boto3.client("s3", endpoint_url=endpoint_url)
dynamodb_resource = boto3.resource("dynamodb", endpoint_url=endpoint_url)
sns_client = boto3.client("sns", endpoint_url=endpoint_url)

table = dynamodb_resource.Table(DYNAMODB_TABLE_NAME)


def handler(event, context):
    """
    Fungsi Handler Utama Lambda
    Terpicu otomatis saat ada event s3:ObjectCreated
    """
    print("=== [LAMBDA PROCESSOR] MEMULAI PEMROSESAN FILE ===")

    try:
        # 1. Ambil Nama Bucket dan Nama File (Key) dari Event S3
        record = event["Records"][0]
        bucket_name = record["s3"]["bucket"]["name"]
        # Unquote digunakan untuk mengubah karakter URL-encoded (misal %20 jadi spasi)
        file_key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        print(f"File ditemukan: '{file_key}' di Bucket: '{bucket_name}'")

        # 2. Unduh File dari S3
        s3_response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
        file_content = s3_response["Body"].read().decode("utf-8")

        # 3. Proses/Parse Isi File berdasarkan Format (JSON atau CSV)
        total_items = 0
        total_amount = 0.0
        anomalies_found = []

        if file_key.endswith(".json"):
            data = json.loads(file_content)
            # Jika berupa daftar/list transaksi
            items = data if isinstance(data, list) else [data]
            
            for index, item in enumerate(items):
                total_items += 1
                amount = float(item.get("amount", 0))
                total_amount += amount

                # Deteksi Anomali: Transaksi bernilai negatif
                if amount < 0:
                    anomalies_found.append(
                        f"Baris {index + 1}: Transaksi bernilai negatif (${amount})"
                    )

        elif file_key.endswith(".csv"):
            csv_reader = csv.DictReader(io.StringIO(file_content))
            for index, row in enumerate(csv_reader):
                total_items += 1
                amount = float(row.get("amount", 0))
                total_amount += amount

                # Deteksi Anomali: Transaksi bernilai negatif
                if amount < 0:
                    anomalies_found.append(
                        f"Baris {index + 1}: Transaksi bernilai negatif (${amount})"
                    )

        # 4. Simpan Hasil Olahan Data ke DynamoDB
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
        print(f"✅ Data berhasil disimpan ke DynamoDB dengan ID: {record_id}")

        # 5. Jika Ditemukan Anomali, Kirim Notifikasi via AWS SNS
        if anomalies_found and SNS_TOPIC_ARN:
            alert_message = (
                f"🚨 ALARM ANOMALI DATA DETECTED 🚨\n\n"
                f"File Name: {file_key}\n"
                f"Total Records: {total_items}\n"
                f"Jumlah Anomali: {len(anomalies_found)}\n"
                f"Rincian Anomali:\n" + "\n".join(anomalies_found)
            )

            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"Alert: Anomali Data pada File {file_key}",
                Message=alert_message,
            )
            print("⚠️ Alert notifikasi berhasil dikirim ke AWS SNS!")

        return {
            "statusCode": 200,
            "body": json.dumps({"status": "SUCCESS", "record_id": record_id}),
        }

    except Exception as e:
        print(f"❌ Error saat memproses file: {str(e)}")
        raise e
