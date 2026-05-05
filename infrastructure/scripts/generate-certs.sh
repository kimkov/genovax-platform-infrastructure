#!/usr/bin/env bash

set -euo pipefail

# Load common functions and defaults
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/defaults.sh"

# LOCAL DEVELOPMENT ONLY NOTICE
log_warn "THIS SCRIPT IS FOR LOCAL DEVELOPMENT ONLY. FOR PRODUCTION, USE AWS ACM OR CERT-MANAGER."

DOMAIN="api.platform.local"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --domain  Domain name (default: $DOMAIN)"
    echo "  -h, --help    Show this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
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

FULL_CERT_DIR="$PROJECT_ROOT/$CERT_DIR"
mkdir -p "$FULL_CERT_DIR"
chmod 700 "$FULL_CERT_DIR"

acquire_lock

# Temporary files cleanup
cleanup_temp_certs() {
    rm -f "$FULL_CERT_DIR/$DOMAIN.ext" "$FULL_CERT_DIR/$DOMAIN.csr" "$FULL_CERT_DIR/rootCA.srl"
}
register_cleanup cleanup_temp_certs

log_info "Generating SSL Certificates for $DOMAIN in $FULL_CERT_DIR"

# 1. Root CA
if [ ! -f "$FULL_CERT_DIR/rootCA.key" ]; then
    log_info "Creating new Root CA..."
    openssl genrsa -out "$FULL_CERT_DIR/rootCA.key" 4096
    chmod 600 "$FULL_CERT_DIR/rootCA.key"
    openssl req -x509 -new -nodes -key "$FULL_CERT_DIR/rootCA.key" -sha256 -days 1024 \
        -out "$FULL_CERT_DIR/rootCA.crt" -subj "/C=US/O=platform/CN=platform-Root-CA"
fi

# 2. Domain certificate
log_info "Creating certificate for $DOMAIN..."
openssl genrsa -out "$FULL_CERT_DIR/$DOMAIN.key" 2048
chmod 600 "$FULL_CERT_DIR/$DOMAIN.key"

openssl req -new -key "$FULL_CERT_DIR/$DOMAIN.key" -out "$FULL_CERT_DIR/$DOMAIN.csr" \
    -subj "/C=US/O=platform/CN=$DOMAIN"

# 3. Signature (SAN support)
echo "subjectAltName = DNS:$DOMAIN, DNS:app.platform.local, DNS:localhost" > "$FULL_CERT_DIR/$DOMAIN.ext"

openssl x509 -req -in "$FULL_CERT_DIR/$DOMAIN.csr" -CA "$FULL_CERT_DIR/rootCA.crt" -CAkey "$FULL_CERT_DIR/rootCA.key" \
    -CAcreateserial -out "$FULL_CERT_DIR/$DOMAIN.crt" -days 365 -sha256 -extfile "$FULL_CERT_DIR/$DOMAIN.ext"

log_success "Certificates generated successfully."
