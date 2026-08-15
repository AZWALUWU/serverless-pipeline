# Use compact Python base image (slim)
FROM python:3.10-slim

# Set working directory inside the container
WORKDIR /app

# Copy dependencies list file
COPY requirements.txt .

# Install Python packages/libraries
RUN pip install --no-cache-dir -r requirements.txt

# Copy entire application code into the container
COPY . .

# Expose port 8000 for external access
EXPOSE 8000

# Command to run FastAPI when the container starts
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]