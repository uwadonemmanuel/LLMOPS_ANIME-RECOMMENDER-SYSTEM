## Parent image - Updated to Python 3.12 to match local development
FROM python:3.12-slim

## Essential environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TOKENIZERS_PARALLELISM=false

## Work directory inside the docker container
WORKDIR /app

## Installing system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

## Copy requirements first for better Docker layer caching
COPY requirements.txt .
COPY install_requirements.py .

## Install requirements with SSL error retry support
RUN python3 install_requirements.py || \
    pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org --trusted-host pypi.python.org -r requirements.txt

## Copy the rest of the application
COPY . .

## Run setup.py (if needed)
RUN pip install --no-cache-dir -e . || true

## Pre-download embedding model (optional - comment out if you want it to download on first use)
# RUN python3 download_embedding_model.py || true

# Used PORTS
EXPOSE 8501

# Run the app 
CMD ["streamlit", "run", "app/app.py", "--server.port=8501", "--server.address=0.0.0.0", "--server.headless=true"]