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

# ############################################
# # Run all configured pre-commit hooks
# ############################################
# run_pre_commit_hooks() {
#     log "STEP" "Running all pre-commit checks..."
#     local hooks=(
#         "check-yaml"
#         "end-of-file-fixer"
#         "trailing-whitespace"
#         "check-added-large-files"
#         "check-vcs-permalinks"
#         "check-symlinks"
#         "destroyed-symlinks"
#         "black"
#         "codespell"
#         "gitleaks"
#     )

#     local exit_code=0
#     for hook in "${hooks[@]}"; do
#         log "INFO" "Running $hook..."
#         if ! pre-commit run "$hook" --all-files; then
#             log "WARN" "$hook found issues that need fixing."
#             exit_code=1
#         fi
#     done

#     return $exit_code
# }

############################################
# Main Execution Flow
############################################
main() {
    echo -e "\n\033[0;34m================================\033[0m"
    log "STEP" "Starting Pre-commit Setup and Checks"
    echo -e "\033[0;34m================================\033[0m\n"

      # Skip run if inside an active git commit
    if [[ "${GIT_DIR:-}" == *".git"* ]]; then
        log "INFO" "Detected Git hook execution — skipping manual checks."
        exit 0
    fi

    # Optional --skip-run flag
    local skip_run=false
    if [[ "${1:-}" == "--skip-run" ]]; then
        skip_run=true
        log "INFO" "Skipping immediate pre-commit run (hooks will still be installed)."
    fi

    check_dependencies
    setup_pre_commit_config
    install_pre_commit_hooks

    if [[ "$skip_run" == false ]]; then
        if ! run_pre_commit_hooks; then
            echo -e "\n\033[0;31m================================\033[0m"
            log "ERROR" "❌ Some checks failed — please review and fix."
            echo -e "\033[0;31m================================\033[0m\n"
            exit 1
        fi
    fi
    
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
