#!/usr/bin/env bash

set -euo pipefail

# Load common functions and defaults
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/defaults.sh"

OUTPUT_DIR="$PROJECT_ROOT/test-results/security"
FORMAT="text"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -o, --output-dir  Directory for reports (default: $OUTPUT_DIR)"
    echo "  -j, --json        Output in JSON format"
    echo "  -h, --help        Show this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -j|--json)
            FORMAT="json"
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

mkdir -p "$OUTPUT_DIR"

acquire_lock

log_info "Starting Security Scan Suite (Format: $FORMAT)"

# 1. Checkov (IaC Static Analysis)
log_info "Running Checkov (IaC Static Analysis)"
CHECKOV_ARGS="-d $TERRAFORM_DIR --quiet"
if [[ "$FORMAT" == "json" ]]; then
    run_tool "checkov" "bridgecrew/checkov" "$CHECKOV_ARGS --output json" "true" > "$OUTPUT_DIR/checkov.json" || log_warn "Checkov found issues."
else
    run_tool "checkov" "bridgecrew/checkov" "$CHECKOV_ARGS --compact"
fi

# 2. TFLint
log_info "Running TFLint (Terraform)"
TFLINT_ARGS="--recursive"
if [[ "$FORMAT" == "json" ]]; then
    run_tool "tflint" "ghcr.io/terraform-linters/tflint" "$TFLINT_ARGS --format json" "true" > "$OUTPUT_DIR/tflint.json" || log_warn "TFLint found issues."
else
    run_tool "tflint" "ghcr.io/terraform-linters/tflint" "$TFLINT_ARGS"
fi

# 3. Search for secrets (TruffleHog)
log_info "Running TruffleHog (Secrets Scan)"
if [[ "$FORMAT" == "json" ]]; then
    # Note: TruffleHog has a slightly different argument structure for its docker vs local
    if check_dependency "trufflehog"; then
        trufflehog filesystem "$PROJECT_ROOT" --only-verified --fail --json > "$OUTPUT_DIR/trufflehog.json" || log_warn "TruffleHog found potential secrets."
    else
        log_info "trufflehog not found locally, running via Docker and saving to $OUTPUT_DIR/trufflehog.json"
        docker run --rm $DOCKER_USER_ARG -v "$PROJECT_ROOT:/src" trufflesecurity/trufflehog filesystem /src --only-verified --fail --json > "$OUTPUT_DIR/trufflehog.json" || log_warn "TruffleHog found potential secrets."
    fi
else
    if check_dependency "trufflehog"; then
        trufflehog filesystem "$PROJECT_ROOT" --only-verified --fail
    else
        log_info "trufflehog not found locally, running via Docker..."
        docker run --rm $DOCKER_USER_ARG -v "$PROJECT_ROOT:/src" trufflesecurity/trufflehog filesystem /src --only-verified --fail
    fi
fi

log_success "Security checks execution completed. Reports are in $OUTPUT_DIR"
