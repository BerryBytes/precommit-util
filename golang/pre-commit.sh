#!/usr/bin/env bash

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

#######################################
# Color-coded logger
# Globals:
#   None
# Arguments:
#   $1: Log level (INFO, WARN, ERROR, STEP)
#   $2+: Log message
#######################################
log() {
    local level="$1"; shift
    local color reset='\033[0m'
    case "$level" in
        INFO)  color='\033[0;32m' ;; # Green
        WARN)  color='\033[1;33m' ;; # Yellow
        ERROR) color='\033[0;31m' ;; # Red
        STEP)  color='\033[0;34m' ;; # Blue
        *)     color='\033[0m' ;;
    esac
    echo -e "${color}[$level] $*${reset}"
}

#######################################
# Check required dependencies
#######################################
check_dependencies() {
    log "STEP" "Checking dependencies"
    local deps=("pre-commit" "gitleaks" "go")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if ((${#missing[@]} > 0)); then
        log "ERROR" "Missing dependencies: ${missing[*]}"
        log "INFO" "Please install the missing dependencies and try again."
        return 1
    fi

    if ! command -v commitlint &>/dev/null; then
        log "INFO" "Installing commitlint globally..."
        npm install -g @commitlint/cli @commitlint/config-conventional
    fi
}

#######################################
# Generate pre-commit config if missing
#######################################
setup_pre_commit_config() {
    local file=".pre-commit-config.yaml"
    log "STEP" "Setting up pre-commit configuration"

    if [[ -f "$file" ]]; then
        log "INFO" "$file already exists — skipping creation"
        return
    fi

    cat > "$file" <<'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
        args: ["--allow-multiple-documents"]
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files
      - id: check-vcs-permalinks
      - id: check-symlinks
      - id: destroyed-symlinks

  - repo: https://github.com/TekWizely/pre-commit-golang
    rev: v1.0.0-rc.1
    hooks:
      - id: go-fmt
        args: [-w]
      - id: go-imports            # Auto-fix and sort imports
      - id: go-vet                # Static analysis
      - id: go-lint               # Lightweight linter
      - id: go-mod-tidy           # Ensure go.mod & go.sum are tidy
    #   - id: go-test               # Run tests before commit
    #   - id: go-sec                # Run gosec for security scanning

  # ✅ Go static analysis (stronger linting)
  - repo: https://github.com/golangci/golangci-lint
    rev: v1.59.1
    hooks:
      - id: golangci-lint
        args: ["run", "--out-format=colored-line-number"]
        additional_dependencies: []

  - repo: https://github.com/codespell-project/codespell
    rev: v2.2.5
    hooks:
      - id: codespell
        files: ^.*\.(py|c|h|md|rst|yml|go|sh|sql|tf|yaml)$
        exclude: ^.*(_test\.go|\.min\.js|\.map)$
        args: ["--ignore-words-list", "hist,nd"]

  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]

#    # ✅ Prevent large files and merge conflicts
#   - repo: https://github.com/pre-commit/merge-conflict-hooks
#     rev: v1.3.0
#     hooks:
#       - id: detect-merge-conflict
EOF

    log "INFO" "$file created successfully."
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
    
    # Run all hooks in a single pass, let output flow naturally
    if pre-commit run --all-files; then
        return 0
    else
        return 1
    fi
}

#######################################
# Main flow
#######################################
main() {
    echo -e "\n\033[0;34m================================\033[0m"
    log "STEP" "Starting Pre-commit Checks"
    echo -e "\033[0;34m================================\033[0m\n"

    check_dependencies
    setup_pre_commit_config
    install_pre_commit_hooks

    if run_pre_commit_hooks; then
        echo -e "\n\033[0;32m======================================\033[0m"
        log "INFO" "✅ All pre-commit checks passed successfully!"
        echo -e "\033[0;32m========================================\033[0m\n"
    else
        echo -e "\n\033[0;33m======================================\033[0m"
        log "WARN" "⚠️  Some checks failed — please review and fix."
        echo -e "\033[0;33m========================================\033[0m\n"
        exit 1
    fi
}

main "$@"
