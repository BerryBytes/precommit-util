#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Log messages with color-coded levels
# Args:
#   $1: Level (INFO, WARN, ERROR, STEP)
#   $2+: Message to display
log() {
    local level="$1"
    shift
    local color
    case "$level" in
        "INFO")  color='\033[0;32m';;  # Green
        "WARN")  color='\033[1;33m';;  # Yellow
        "ERROR") color='\033[0;31m';;  # Red
        "STEP")  color='\033[0;34m';;  # Blue
        *)       color='\033[0m';;     # Default
    esac
    echo -e "${color}[$level] $*\033[0m"
}

# Check if required tools are installed
check_dependencies() {
  log "STEP" "Checking dependencies"
  local missing_deps=()
  local deps=("pre-commit" "gitleaks" "go")

  for cmd in "${deps[@]}"; do
      if ! command -v "$cmd" >/dev/null 2>&1; then
          missing_deps+=("$cmd")
      fi
  done

  if [ ${#missing_deps[@]} -gt 0 ]; then
      log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
      log "INFO" "Please install the missing dependencies and try again."
      return 1
  fi
  return 0
}

# Create pre-commit configuration file if it doesn't exist
setup_pre_commit_config() {
  log "STEP" "Setting Up Pre-commit Config"
  local pre_commit_config=".pre-commit-config.yaml"

  if [ -f "$pre_commit_config" ]; then
      log "INFO" "Existing $pre_commit_config found, skipping creation"
      return 0
  fi

  cat > "$pre_commit_config" <<EOF
repos:
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.3.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
        args: [feat, fix, ci, chore, test]
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
        verbose: true
      - id: end-of-file-fixer
        verbose: true
      - id: trailing-whitespace
        verbose: true
      - id: check-added-large-files
        verbose: true
      - id: check-vcs-permalinks
        verbose: true
      - id: check-symlinks
        verbose: true
      - id: destroyed-symlinks
        verbose: true
  - repo: https://github.com/TekWizely/pre-commit-golang
    rev: v1.0.0-rc.1
    hooks:
      - id: go-fmt
        args: [-w]
        verbose: true
  - repo: https://github.com/codespell-project/codespell
    rev: v2.2.5
    hooks:
      - id: codespell
        files: ^.*\.(py|c|h|md|rst|yml|go|sh|sql|tf|yaml)$
        exclude: ^.*(_test\.go|\.min\.js|\.map)$
        args: ["--ignore-words-list", "hist,nd"]
        verbose: true
  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]
        verbose: true
EOF
  log "INFO" "$pre_commit_config created."
}


run_formatting_hooks() {
    log "STEP" "Running Formatting Checks"
    pre-commit install || { log "ERROR" "Failed to install pre-commit hooks"; return 1; }
    pre-commit install --hook-type commit-msg || { log "ERROR" "Failed to install commit-msg hook"; return 1; 

    
    local formatting_hooks=("conventional-pre-commit" "golangci-lint" "go-fmt" "go-imports" "no-go-testing" "go-unit-tests" "check-yaml" "end-of-file-fixer" "trailing-whitespace" "check-added-large-files" "check-vcs-permalinks" "check-symlinks" "destroyed-symlinks" "codespell" "gitleaks")
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

# Main execution flow
main() {
  echo -e "\n\033[0;34m================================\033[0m"
  log "STEP" "Starting Pre-commit Checks"
  echo -e "\033[0;34m================================\033[0m\n"

  check_dependencies || exit 1
  setup_pre_commit_config
  run_formatting_hooks
  local result=$?

  if [ $result -eq 0 ]; then
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
