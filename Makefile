.PHONY: setup plan scan help

# Variables
ENV ?= dev
TF_DIR = infrastructure/terraform/environments/$(ENV)

help:
	@echo "GenovaX Platform Infrastructure Management"
	@echo "Usage:"
	@echo "  make setup        - Initialize local environment (run bootstrap script)"
	@echo "  make plan ENV=dev  - Run Terraform plan for specific environment (default: dev)"
	@echo "  make scan         - Run security scans (Checkov, TFLint)"

setup:
	@chmod +x infrastructure/scripts/*.sh
	@./infrastructure/scripts/bootstrap.sh

plan:
	@cd $(TF_DIR) && terraform init && terraform plan

scan:
	@chmod +x infrastructure/scripts/check-security.sh
	@./infrastructure/scripts/check-security.sh
