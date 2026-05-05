#!/usr/bin/env bash

set -euo pipefail

# Load common functions and defaults
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/defaults.sh"

SEED_FILE="$PROJECT_ROOT/infrastructure/db/seeds/dev-seed.sql"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -s, --seed-file  Path to SQL seed file (default: $SEED_FILE)"
    echo "  -h, --help       Show this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--seed-file)
            SEED_FILE="$2"
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

# Safety Guard for Production
check_production_restriction

acquire_lock

# Validate database container
if [[ -z "$(docker ps -q -f name="^/${DB_CONTAINER}$")" ]]; then
    log_error "Database container '$DB_CONTAINER' is not running."
    exit 1
fi

if [[ ! -f "$SEED_FILE" ]]; then
    log_error "Seed file not found: $SEED_FILE"
    exit 1
fi

log_info "Seeding database with file: $SEED_FILE (Env: $ENVIRONMENT)"

# Waiting for DB readiness
log_info "Waiting for database to be ready..."
MAX_RETRIES=10
RETRY_COUNT=0
until docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" > /dev/null 2>&1 || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  log_info "Database not ready yet... ($RETRY_COUNT/$MAX_RETRIES)"
  sleep 3
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    log_error "Database connection timed out."
    exit 1
fi

# SQL execution
log_info "Executing SQL seed..."
if [[ "$ENVIRONMENT" == "dev" ]]; then
    # For local dev, using docker exec is usually fine as we use standard postgres images
    docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < "$SEED_FILE"
else
    # Production-grade approach: use a temporary client container
    # This assumes the container is in a reachable network or we use host/container networking
    log_info "Using temporary client container for seeding..."
    docker run --rm -i \
        --network container:"$DB_CONTAINER" \
        -e PGPASSWORD="${DB_PASSWORD:-}" \
        postgres:16-alpine \
        psql -h localhost -U "$DB_USER" -d "$DB_NAME" < "$SEED_FILE"
fi

log_success "Database successfully seeded."
