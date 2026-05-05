#!/usr/bin/env bash

# Shared configuration for Platform infrastructure scripts

# Environment
export ENVIRONMENT="${ENVIRONMENT:-dev}"

# Required Tool Versions
export JAVA_REQUIRED="21.0.0"
export NODE_REQUIRED="20.0.0"
export TERRAFORM_REQUIRED="1.5.0"
export PNPM_REQUIRED="9.0.0"

# Database Configuration
export DB_CONTAINER="${DB_CONTAINER:-platform-db}"
export DB_USER="${DB_USER:-platform_user}"
export DB_NAME="${DB_NAME:-platform}"

# Paths (relative to PROJECT_ROOT)
export CERT_DIR="infrastructure/certs"
export LOG_DIR="logs"
export LOG_FILE="$PROJECT_ROOT/$LOG_DIR/infrastructure.log"
export TERRAFORM_DIR="infrastructure/terraform"

# Security Checks
export CHECKOV_QUIET="true"
export TRUFFLEHOG_FAIL="true"
