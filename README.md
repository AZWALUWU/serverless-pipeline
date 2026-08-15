## Serverless & Event-Driven Data Processing Pipeline

This project designs and implements a **Serverless & Event-Driven Data Processing Pipeline** focused on **Cost Optimization** and cloud-native automation. The pipeline eliminates idle compute costs (24/7 active servers without workload) by leveraging event-driven computing.

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

| Layer / Component | Tech Stack | Primary Role & Functionality |
| --- | --- | --- |
| **Infrastructure as Code** | Terraform | Automatically provisions S3, Lambda, DynamoDB, and SNS resources on LocalStack. |
| **Cloud Emulation** | LocalStack | Simulates AWS services in a local environment with zero cost. |
| **Data Ingestion API** | FastAPI & Python | REST API service for receiving data file uploads (CSV/JSON). |
| **Serverless Compute** | AWS Lambda (Python) | Automates data processing execution, aggregate calculations, and anomaly detection. |
| **NoSQL Database** | AWS DynamoDB | Stores metadata and aggregation results of processed transactions. |
| **Alerting System** | AWS SNS | Dispatches alert notifications when data anomalies (e.g., negative transactions) are detected. |
| **Container & K8s** | Docker & Kubernetes | Containers for the Upload API and runs housekeeping scripts in an isolated Minikube environment. |
| **Housekeeping & Audit** | Bash Script & K8s CronJob | Runs periodically (cron) to audit S3 storage usage and clean up logs. |
| **CI/CD & DevSecOps** | GitHub Actions & Trivy | Automated linting (`flake8`), Terraform validation, and security vulnerability scanning. |

---

## 📁 Repository Structure

```text
serverless-pipeline/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions CI/CD & Trivy Security Scan pipeline
├── terraform/
│   ├── provider.tf            # AWS Provider configuration (LocalStack path-style)
│   ├── main.tf                # S3 Ingestion Bucket, DynamoDB, and SNS manifests
│   └── lambda.tf              # Lambda Function, IAM Role, and S3 Event Trigger
├── src/
│   ├── api/                   # FastAPI Upload Service code & Dockerfile
│   ├── lambda/                # AWS Lambda Data Processor Python code
│   └── cronjob/               # Log Retention & Housekeeping Agent Bash script
├── k8s/
│   ├── deployment.yaml        # Kubernetes Deployment & Service (NodePort 30090)
│   └── cronjob.yaml           # Kubernetes CronJob for S3 storage audit
├── .gitignore                 # Git ignore patterns for venv, .terraform, and caches
├── docker-compose.yml         # LocalStack container configuration
└── README.md                  # Project documentation

```

---

## 🚀 Quick Start Guide

### System Prerequisites

* Docker & Docker Compose
* Terraform CLI
* Kubernetes CLI (`kubectl`) & Minikube
* Python 3.10+

### 1. Run LocalStack

```bash
docker compose up -d

```

### 2. Provision Cloud Infrastructure via Terraform

```bash
cd terraform
terraform init
terraform apply -auto-approve
cd ..

```

### 3. Deploy Application to Kubernetes (Minikube)

```bash
# Build Upload API Docker image
docker build -t upload-api:v1 src/api/

# Load image into Minikube cluster
minikube image load upload-api:v1

# Apply Kubernetes manifest files
kubectl apply -f k8s/

```

### 4. Test Pipeline End-to-End

```bash
# Upload sample CSV file via Kubernetes Service
curl -X POST "$(minikube service upload-api-service --url)/upload" -F "file=@data_normal.csv"

# Verify processed data output in DynamoDB
aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name processed-data-table

```

---

## 🔒 DevSecOps & Security Scanning

This project includes an automated **GitHub Actions CI/CD** workflow consisting of two main stages:

1. **Code Quality & Validation:** Python syntax error checking (`flake8`) alongside IaC manifest formatting and validation (`terraform validate`).
2. **Security & Vulnerability Scan:** Automated security scanning of the repository, Terraform files, and Docker images using **Trivy Security Scan** to detect vulnerabilities (*HIGH & CRITICAL*).