#!/usr/bin/env bash

set -euo pipefail

# Load common functions and defaults
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/defaults.sh"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -f, --force    Skip confirmation prompt"
    echo "  -h, --help     Show this help message"
    exit 0
}

FORCE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Safety Guard for Production
check_production_restriction

acquire_lock
log_info "Cleaning up platform Resources (Env: $ENVIRONMENT)"

if [[ "$FORCE" == false ]]; then
    echo -e "${RED}WARNING: This will delete Docker volumes, logs, and temporary files.${NC}"
    read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup aborted."
        exit 0
    fi
fi

cd "$PROJECT_ROOT"

# Delete Containers and Volume
log_info "Removing Docker resources..."
if command -v docker-compose &> /dev/null; then
    docker-compose down -v --remove-orphans
else
    log_warn "docker-compose not found, skipping Docker cleanup."
fi

# Delete logs and temporary files
log_info "Clearing logs and temporary assets..."
# Use find to avoid errors with empty directories and globbing
find "$LOG_DIR" -mindepth 1 -delete 2>/dev/null || true
find "$CERT_DIR" -name "*.crt" -o -name "*.key" -o -name "*.csr" -o -name "*.ext" -delete 2>/dev/null || true

# Clean Terraform Cache
log_info "Cleaning Terraform cache..."
find . -type d -name ".terraform" -exec rm -rf {} +

log_success "Cleanup finished. Local environment is reset."
