# Serverless & Event-Driven Data Processing Pipeline

Proyek ini merancang dan mengimplementasikan **Serverless & Event-Driven Data Processing Pipeline** yang berfokus pada **Cost Optimization** dan otomatisasi *cloud-native*. Pipeline ini mengeliminasi *idle compute cost* (server aktif 24/7 tanpa beban kerja) dengan memanfaatkan komputasi berbasis event.

---

## 📌 System Architecture & Event Flow

```text
[User / Client] --(Upload File)--> [FastAPI Service (Kubernetes)]
                                        |
                                        v (Save Raw File)
                             [AWS S3 Ingestion Bucket]
                                        |
                            (s3:ObjectCreated Event)
                                        v
                            [AWS Lambda Data Processor]
                                        |
                  +---------------------+---------------------+
                  | (Save Output)                             | (If Anomaly)
                  v                                           v
         [AWS DynamoDB Table]                      [AWS SNS Alerting]
                  ^                                           |
                  |                                           v
       [K8s CronJob Audit] <----------------------- [Notification]

```

---

## 🛠️ Tech Stack Matrix

| Layer / Komponen | Tech Stack | Peran & Fungsi Utama |
| --- | --- | --- |
| **Infrastructure as Code** | Terraform | Memprovisi resource S3, Lambda, DynamoDB, dan SNS ke LocalStack secara otomatis. |
| **Cloud Emulation** | LocalStack | Mensimulasikan layanan AWS di lingkungan lokal tanpa biaya. |
| **Data Ingestion API** | FastAPI & Python | REST API Service untuk menerima unggahan berkas data (CSV/JSON). |
| **Serverless Compute** | AWS Lambda (Python) | Eksekusi otomatis pemrosesan data, kalkulasi agregat, dan deteksi anomali. |
| **NoSQL Database** | AWS DynamoDB | Menyimpan metadata dan hasil agregasi transaksi yang diproses. |
| **Alerting System** | AWS SNS | Mengirim notifikasi peringatan saat ditemukan anomali data (misal: transaksi negatif). |
| **Container & K8s** | Docker & Kubernetes | Membungkus Upload API dan menjalankan skrip pembersihan secara terisolasi di Minikube. |
| **Housekeeping & Audit** | Bash Script & K8s CronJob | Running secara berkala (cron) untuk audit penggunaan storage S3 dan pembersihan log. |
| **CI/CD & DevSecOps** | GitHub Actions & Trivy | Automated linting (`flake8`), validasi Terraform, dan security vulnerability scan. |

---

## 📁 Repository Structure

```text
serverless-pipeline/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # Pipeline GitHub Actions CI/CD & Trivy Security Scan
├── terraform/
│   ├── provider.tf            # Konfigurasi Provider AWS (LocalStack path-style)
│   ├── main.tf                # Manifes S3 Ingestion Bucket, DynamoDB, dan SNS
│   └── lambda.tf              # Lambda Function, IAM Role, dan S3 Event Trigger
├── src/
│   ├── api/                   # Kode FastAPI Upload Service & Dockerfile
│   ├── lambda/                # Kode Python AWS Lambda Data Processor
│   └── cronjob/               # Skrip Bash Log Retention & Housekeeping Agent
├── k8s/
│   ├── deployment.yaml        # Kubernetes Deployment & Service (NodePort 30090)
│   └── cronjob.yaml           # Kubernetes CronJob untuk audit S3 storage
├── .gitignore                 # Filter lacakan Git untuk venv, .terraform, dan cache
├── docker-compose.yml         # Konfigurasi LocalStack container
└── README.md                  # Dokumentasi proyek

```

---

## 🚀 Quick Start Guide

### Prasyarat System

* Docker & Docker Compose
* Terraform CLI
* Kubernetes CLI (`kubectl`) & Minikube
* Python 3.10+

### 1. Jalankan LocalStack

```bash
docker compose up -d

```

### 2. Provisi Infrastruktur Cloud via Terraform

```bash
cd terraform
terraform init
terraform apply -auto-approve
cd ..

```

### 3. Deploy Aplikasi ke Kubernetes (Minikube)

```bash
# Build Docker image Upload API
docker build -t upload-api:v1 src/api/

# Load image ke dalam kluster Minikube
minikube image load upload-api:v1

# Terapkan periferal manifes Kubernetes
kubectl apply -f k8s/

```

### 4. Uji Coba Pipeline End-to-End

```bash
# Unggah sampel berkas CSV melalui Service Kubernetes
curl -X POST "$(minikube service upload-api-service --url)/upload" -F "file=@data_normal.csv"

# Periksa hasil olahan data di DynamoDB
aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name processed-data-table

```

---

## 🔒 DevSecOps & Security Scanning

Proyek ini dilengkapi alur otomatisasi **GitHub Actions CI/CD** yang terdiri dari dua tahapan utama:

1. **Code Quality & Validation:** Pemeriksaan kesalahan sintaks Python (`flake8`) serta format dan validasi manifes IaC (`terraform validate`).
2. **Security & Vulnerability Scan:** Pemindaian keamanan otomatis pada repositori, file Terraform, dan Docker Image menggunakan **Trivy Security Scan** untuk mendeteksi celah keamanan (*HIGH & CRITICAL*).
