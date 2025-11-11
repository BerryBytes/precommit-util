#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

############################################
# Color-coded logging utility
############################################
log() {
    local level="$1"; shift
    local color reset='\033[0m'
    case "$level" in
        INFO)  color='\033[0;32m' ;;  # Green
        WARN)  color='\033[1;33m' ;;  # Yellow
        ERROR) color='\033[0;31m' ;;  # Red
        STEP)  color='\033[0;34m' ;;  # Blue
        *)     color='\033[0m' ;;
    esac
    echo -e "${color}[$level] $*${reset}"
}

############################################
# Check required dependencies
############################################
check_dependencies() {
    log "STEP" "Checking dependencies..."
    local deps=("python3" "pre-commit")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if ((${#missing[@]} > 0)); then
        log "ERROR" "Missing dependencies: ${missing[*]}"
        log "INFO" "Please install the missing dependencies and try again."
        exit 1
    fi

    if ! command -v commitlint &>/dev/null; then
        log "INFO" "Installing commitlint globally..."
        npm install -g @commitlint/cli @commitlint/config-conventional
    fi
}

############################################
# Create .pre-commit-config.yaml if missing
############################################
setup_pre_commit_config() {
    local config=".pre-commit-config.yaml"
    log "STEP" "Setting up pre-commit configuration..."

    if [[ -f "$config" ]]; then
        log "INFO" "$config already exists — skipping creation."
        return
    fi

    local python_version
    python_version=$(python3 -V | awk '{print $2}' | cut -d. -f1-2)

    cat > "$config" <<EOF
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files
      - id: check-vcs-permalinks
      - id: check-symlinks
      - id: destroyed-symlinks

  - repo: https://github.com/psf/black
    rev: 23.9.1
    hooks:
      - id: black
        args: [--line-length=88]
        language_version: python${python_version}

  - repo: https://github.com/codespell-project/codespell
    rev: v2.2.5
    hooks:
      - id: codespell
        files: ^.*\\.(py|c|h|md|rst|yml|go|sh|sql|tf|yaml)\$
        args: ["--ignore-words-list", "hist,nd"]

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]
EOF

    log "INFO" "$config created successfully."
}

############################################
# Install pre-commit hooks (idempotent)
############################################
install_pre_commit_hooks() {
    log "STEP" "Installing pre-commit hooks..."
    if pre-commit install >/dev/null 2>&1; then
        log "INFO" "Pre-commit hooks installed successfully."
    else
        log "ERROR" "Failed to install pre-commit hooks."
        exit 1
    fi
}

############################################
# Run all configured pre-commit hooks ONCE
############################################
run_pre_commit_hooks() {
    log "STEP" "Running all pre-commit checks (single pass)..."
    
    # Run all hooks in a single pass with --all-files
    if pre-commit run --all-files; then
        log "INFO" "All checks passed."
        return 0
    else
        log "WARN" "Some checks failed or made changes."
        return 1
    fi
}

############################################
# Main Execution Flow
############################################
main() {
    echo -e "\n\033[0;34m================================\033[0m"
    log "STEP" "Starting Pre-commit Setup and Checks"
    echo -e "\033[0;34m================================\033[0m\n"

    check_dependencies
    setup_pre_commit_config
    install_pre_commit_hooks
    
    if run_pre_commit_hooks; then
        echo -e "\n\033[0;32m================================\033[0m"
        log "INFO" "✅ All pre-commit checks passed successfully!"
        echo -e "\033[0;32m================================\033[0m\n"
    else
        echo -e "\n\033[0;31m================================\033[0m"
        log "ERROR" "❌ Some checks failed — please review and fix."
        echo -e "\033[0;31m================================\033[0m\n"
        exit 1
    fi
}

main "$@"