# Menggunakan base image Python versi ringkas (slim)
FROM python:3.10-slim

# Menentukan folder kerja di dalam container
WORKDIR /app

# Menyalin file daftar dependencies
COPY requirements.txt .

# Menginstal paket/library Python
RUN pip install --no-cache-dir -r requirements.txt

# Menyalin seluruh kode aplikasi ke dalam container
COPY . .

# Membuka port 8000 untuk diakses dari luar
EXPOSE 8000

# Perintah untuk menjalankan FastAPI saat container dinyalakan
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
