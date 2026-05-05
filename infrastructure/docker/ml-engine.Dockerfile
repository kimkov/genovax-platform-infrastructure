FROM python:3.11.9-slim AS builder

# Installing compilation tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Using virtualenv to isolate dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copying module sources
COPY modules/ml-shared-lib modules/ml-shared-lib
COPY modules/ml-engine modules/ml-engine

# Installing libraries without development tools (dev-dependencies)
RUN pip install --no-cache-dir ./modules/ml-shared-lib
RUN pip install --no-cache-dir ./modules/ml-engine

# Runtime
FROM python:3.11.9-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Creating the user genovax
RUN groupadd -r genovax && useradd -r -g genovax genovax

WORKDIR /app

# We copy the prepared virtual environment and the necessary source files
COPY --from=builder /opt/venv /opt/venv
COPY modules/ml-engine/src modules/ml-engine/src
COPY modules/ml-shared-lib/src modules/ml-shared-lib/src

# Preparing the log directory
RUN mkdir -p /var/log/genovax && \
    chown -R genovax:genovax /var/log/genovax && \
    chmod 755 /var/log/genovax

ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONPATH="/app/modules/ml-engine/src:/app/modules/ml-shared-lib/src"
ENV PYTHONUNBUFFERED=1
ENV AUDIT_LOG_PATH="/var/log/genovax/audit_ml_engine.log"

USER genovax

EXPOSE 8000

# API Performance Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Launching an application via uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]