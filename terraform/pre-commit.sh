#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Logger function for consistent output
log() {
    local level=$1
    shift
    local color
    case "$level" in
        "INFO") color='\033[0;32m';;
        "WARN") color='\033[1;33m';;
        "ERROR") color='\033[0;31m';;
        "STEP") color='\033[0;34m';;
        *) color='\033[0m';;
    esac
    echo -e "${color}[$level] $*\033[0m"
}

# Check if required tools are installed
check_dependencies() {
    local missing_deps=()
    for cmd in terraform tflint tfsec pre-commit; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log "INFO" "Please install the missing dependencies:"
        log "INFO" "  - Terraform: https://developer.hashicorp.com/terraform/downloads"
        log "INFO" "  - TFLint: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"
        log "INFO" "  - TFSec: curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash"
        log "INFO" "  - Pre-commit: pip install pre-commit"
        exit 1
    fi
}

setup_pre_commit_config() {
    log "STEP" "Setting Up Pre-commit Config"
    local pre_commit_config=".pre-commit-config.yaml"
    if [ ! -f "$pre_commit_config" ]; then
        cat > "$pre_commit_config" <<EOF
repos:
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v2.1.1
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
        args: [feat, fix, ci, chore, test]
  - repo: https://github.com/terraform-docs/terraform-docs
    rev: "v0.16.0"
    hooks:
      - id: terraform-docs-go
        args: ["markdown", "table", "--output-file", "README.md", "./"]
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: "v1.74.1"
    hooks:
      - id: terraform_fmt
      - id: terraform_tflint
      - id: terraform_validate
      - id: terraform_tfsec
  - repo: https://github.com/codespell-project/codespell
    rev: v2.2.5
    hooks:
      - id: codespell
        files: ^.*\.(py|c|h|md|rst|yml|go|sh|sql|tf|yaml)$
        args: ["--ignore-words-list", "hist,nd"]
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]
  

EOF
        log "INFO" "$pre_commit_config created."
    fi
}

run_formatting_hooks() {
    log "STEP" "Running Formatting Checks"
    pre-commit install || { log "ERROR" "Failed to install pre-commit hooks"; return 1; }
    pre-commit install --hook-type commit-msg || { log "ERROR" "Failed to install commit-msg hook"; return 1; 



    local formatting_hooks=("terraform-docs-go" "terraform_fmt" "terraform_tflint" "terraform_validate" "terraform_tfsec" "codespell" "conventional-pre-commit" )
    local exit_code=0
    for hook in "${formatting_hooks[@]}"; do
        log "INFO" "Running $hook..."
        if ! pre-commit run "$hook" --all-files; then
            log "WARN" "$hook found issues that need fixing"
            exit_code=1
        fi
    done
    return $exit_code
    }
    
}


main() {
    echo -e "\n\033[0;34m================================\033[0m"
    log "STEP" "Starting Terraform Checks"
    echo -e "\033[0;34m================================\033[0m\n"

    # Run each step independently, collecting exit codes
    check_dependencies
    # clean_up_blank_lines_and_spaces
    setup_pre_commit_config
    run_formatting_hooks
 

    if [ $? -eq 0 ]; then
        echo -e "\n\033[0;32m================================\033[0m"
        log "INFO" "All checks completed successfully! ✨"
        echo -e "\033[0;32m================================\033[0m\n"
    else
        echo -e "\n\033[0;31m================================\033[0m"
        log "ERROR" "Issues were found. Please fix them and try again."
        echo -e "\033[0;31m================================\033[0m\n"
        exit 1
    fi
}

main "$@"