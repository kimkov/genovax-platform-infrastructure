#!/usr/bin/env bash

# Centralized common functions for GenovaX infrastructure scripts

set -euo pipefail

# Determine project root directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
export PROJECT_ROOT

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
_log_to_file() {
    local level=$1
    local message=$2
    if [[ -n "${LOG_FILE:-}" ]]; then
        mkdir -p "$(dirname "$LOG_FILE")"
        echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [$level] $message" >> "$LOG_FILE"
    fi
}

log_info() {
    echo -e "${BLUE}[INFO] $(date +'%Y-%m-%dT%H:%M:%S%z') - $1${NC}"
    _log_to_file "INFO" "$1"
}

log_success() {
    echo -e "${GREEN}[OK] $(date +'%Y-%m-%dT%H:%M:%S%z') - $1${NC}"
    _log_to_file "SUCCESS" "$1"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $(date +'%Y-%m-%dT%H:%M:%S%z') - $1${NC}"
    _log_to_file "WARN" "$1"
}

log_error() {
    echo -e "${RED}[ERROR] $(date +'%Y-%m-%dT%H:%M:%S%z') - $1${NC}" >&2
    _log_to_file "ERROR" "$1"
}

# Cleanup registry
CLEANUP_FUNCS=()
register_cleanup() {
    CLEANUP_FUNCS+=("$1")
}

execute_cleanup() {
    if [[ ${#CLEANUP_FUNCS[@]} -gt 0 ]]; then
        for func in "${CLEANUP_FUNCS[@]}"; do
            $func || true
        done
    fi
}
trap execute_cleanup EXIT

# Locking mechanism to prevent parallel execution
acquire_lock() {
    local script_name
    script_name=$(basename "$0")
    local lock_dir="$PROJECT_ROOT/.tmp/locks"
    local lock_file="$lock_dir/${script_name}.lock"
    
    mkdir -p "$lock_dir"
    
    if [[ -f "$lock_file" ]]; then
        local pid
        pid=$(cat "$lock_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_error "Another instance of $script_name (PID: $pid) is already running."
            exit 1
        fi
    fi
    echo $$ > "$lock_file"
    
    cleanup_lock() {
        rm -f "$PROJECT_ROOT/.tmp/locks/$(basename "$0").lock"
    }
    register_cleanup cleanup_lock
}

# Production safety guard
check_production_restriction() {
    local env="${ENVIRONMENT:-dev}"
    if [[ "$env" == "prod" || "$env" == "production" ]]; then
        log_error "This action is RESTRICTED in production environment!"
        exit 1
    fi
}

# Dependency checker with optional docker fallback
check_dependency() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        return 1
    fi
    return 0
}

# Run tool locally or via Docker
DOCKER_USER_ARG=""
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" ]]; then
    DOCKER_USER_ARG="-u $(id -u):$(id -g)"
fi
export DOCKER_USER_ARG

# Usage: run_tool "checkov" "bridgecrew/checkov" "-d . --quiet"
run_tool() {
    local cmd=$1
    local image=$2
    local args=$3
    local silent=${4:-false}

    if check_dependency "$cmd"; then
        [[ "$silent" == "false" ]] && log_info "Running $cmd locally..."
        # shellcheck disable=SC2086
        $cmd $args
    else
        [[ "$silent" == "false" ]] && log_info "$cmd not found locally. Trying to run via Docker ($image)..."
        if check_dependency "docker"; then
            # shellcheck disable=SC2086
            docker run --rm $DOCKER_USER_ARG -v "$PROJECT_ROOT:/src" -w /src "$image" $args
        else
            log_error "Neither $cmd nor docker is installed. Cannot proceed."
            exit 1
        fi
    fi
}

# Strict version comparison
# Returns 0 if $1 >= $2
version_ge() {
    printf '%s\n%s' "$2" "$1" | sort -C -V
}
