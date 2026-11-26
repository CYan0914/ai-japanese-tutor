FROM python:3.12-slim

WORKDIR /app

# Install system deps needed for audio processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY app/ app/

# Fly.io expects port 8080
EXPOSE 8080

# P0: 2 workers so one slow LLM/STT call doesn't head-of-line block all
# traffic. Needs the 2GB VM in fly.toml (each worker loads its own
# Whisper model ~150MB). Single worker + sync STT/LLM = whole server stalls.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]
