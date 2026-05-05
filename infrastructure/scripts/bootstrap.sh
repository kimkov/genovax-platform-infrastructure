#!/usr/bin/env bash

set -euo pipefail

# Load common functions and defaults
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/defaults.sh"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help    Show this help message"
    exit 0
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

acquire_lock
log_info "Platform Platform Bootstrap starting..."

# Improved version check
check_tool_version() {
    local tool=$1
    local expected=$2
    local cmd=$3
    local version_extract_pattern=${4:-}

    if ! command -v "${cmd%% *}" &> /dev/null; then
        log_error "$tool is not installed."
        exit 1
    fi

    local current_version
    if [[ -n "$version_extract_pattern" ]]; then
        current_version=$($cmd 2>&1 | grep -oE "$version_extract_pattern" | head -n 1)
    else
        current_version=$($cmd 2>&1 | head -n 1)
    fi

    # Remove 'v' prefix if present
    current_version="${current_version#v}"

    if version_ge "$current_version" "$expected"; then
        log_success "$tool version $current_version (>= $expected) found."
    else
        log_error "$tool version at least $expected is required. Found: $current_version"
        exit 1
    fi
}

log_info "Step 1: Checking prerequisites..."
check_tool_version "Java" "$JAVA_REQUIRED" "java -version" "[0-9]+\.[0-9]+\.[0-9]+"
check_tool_version "Node" "$NODE_REQUIRED" "node -v" "[0-9]+\.[0-9]+\.[0-9]+"
check_tool_version "Terraform" "$TERRAFORM_REQUIRED" "terraform version" "[0-9]+\.[0-9]+\.[0-9]+"
check_tool_version "pnpm" "$PNPM_REQUIRED" "pnpm -v" "[0-9]+\.[0-9]+\.[0-9]+"

# Docker Check
if ! docker info >/dev/null 2>&1; then
    log_error "Docker is not running or not installed."
    exit 1
fi
log_success "Docker is running."

log_info "Step 2: Configuring environment variables..."
cd "$PROJECT_ROOT"
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        ENCR_KEY=$(openssl rand -base64 32)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/ENCRYPTION_KEY=/ENCRYPTION_KEY=$ENCR_KEY/" .env
        else
            sed -i "s/ENCRYPTION_KEY=/ENCRYPTION_KEY=$ENCR_KEY/" .env
        fi
        log_success ".env created with generated security keys."
    else
        log_error ".env.example not found in $PROJECT_ROOT. Cannot create .env."
        exit 1
    fi
else
    log_info "Using existing .env file."
fi

log_info "Step 3: Setting up local infrastructure..."
if [ -d "frontend" ]; then
    log_info "Installing frontend dependencies..."
    (cd frontend && pnpm install)
else
    log_warn "frontend directory not found, skipping pnpm install."
fi

log_success "Bootstrap complete! Ready for development."
