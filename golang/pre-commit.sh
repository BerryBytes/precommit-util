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
EOF

    log "INFO" "$file created successfully."
}

#######################################
# Run pre-commit hooks across the repo
#######################################
run_formatting_hooks() {
    log "STEP" "Running formatting and linting checks"
    pre-commit install >/dev/null 2>&1 || {
        log "ERROR" "Failed to install pre-commit hooks"
        return 1
    }

    local hooks=(
        "golangci-lint" "go-fmt" "go-imports"
        "no-go-testing" "go-unit-tests"
        "check-yaml" "end-of-file-fixer" "trailing-whitespace"
        "check-added-large-files" "check-vcs-permalinks"
        "check-symlinks" "destroyed-symlinks"
        "codespell" "gitleaks"
    )

    local exit_code=0
    for hook in "${hooks[@]}"; do
        log "INFO" "Running $hook..."
        if ! pre-commit run "$hook" --all-files; then
            log "WARN" "$hook found issues — please review and fix."
            exit_code=1
        fi
    done
    return $exit_code
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
    if run_formatting_hooks; then
        echo -e "\n\033[0;32m================================\033[0m"
        log "INFO" "All checks completed successfully! ✨"
        echo -e "\033[0;32m================================\033[0m\n"
    else
        echo -e "\n\033[0;31m================================\033[0m"
        log "ERROR" "Some checks failed — fix issues and re-run."
        echo -e "\033[0;31m================================\033[0m\n"
        exit 1
    fi
}

main "$@"
