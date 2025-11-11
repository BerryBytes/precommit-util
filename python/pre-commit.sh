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
    local required_tools=("python3" "pre-commit")
    local missing_deps=()

    for cmd in "${required_tools[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log "INFO" "Please install the missing dependencies and try again."
        exit 1
    fi

    if ! command -v commitlint >/dev/null 2>&1; then
        log "INFO" "Installing commitlint..."
        npm install -g @commitlint/cli @commitlint/config-conventional
    fi

  return 0
}

# Set up pre-commit configuration
setup_pre_commit_config() {
    log "STEP" "Setting Up Pre-commit Config"
    local pre_commit_config=".pre-commit-config.yaml"

    if [ -f "$pre_commit_config" ]; then
        log "INFO" "Existing $pre_commit_config found, skipping creation"
        return 0
    fi

    # Detect Python version dynamically
    local python_version
    python_version=$(python3 -V | awk '{print $2}' | cut -d. -f1-2)

    cat > "$pre_commit_config" <<EOF

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
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

    log "INFO" "Pre-commit config created at $pre_commit_config."
}

# # Ensure pre-commit hooks are installed only once
# install_pre_commit_hooks_once() {
#     log "STEP" "Ensuring Pre-commit Hooks Are Installed"

#     if [ ! -f .git/hooks/pre-commit ] || [ ! -f .git/hooks/commit-msg ]; then
#         pre-commit install
#         pre-commit install --hook-type commit-msg
#         log "INFO" "Pre-commit hooks installed successfully"
#     else
#         log "INFO" "Pre-commit hooks already installed, skipping"
#     fi
# }

# Run formatting and linting hooks manually (optional)
run_formatting_hooks() {
    log "STEP" "Running Formatting Checks"
    pre-commit install || { log "ERROR" "Failed to install pre-commit hooks"; return 1; 
    # pre-commit install --hook-type commit-msg || { log "ERROR" "Failed to install commit-msg hook"; return 1; 


    local formatting_hooks=("check-yaml" "end-of-file-fixer" "trailing-whitespace" "check-added-large-files" "check-vcs-permalinks" "check-symlinks" "destroyed-symlinks" "black" "codespell" "gitleaks")
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

# Run all formatting and linting hooks
# Returns: 0 if all hooks pass, 1 if any fail
 log "STEP" "Running Formatting Checks"
    pre-commit install || { log "ERROR" "Failed to install pre-commit hooks"; return 1; 
    # pre-commit install --hook-type commit-msg || { log "ERROR" "Failed to install commit-msg hook"; return 1;

  
  # Define hooks to run
  local formatting_hooks=("check-yaml" "end-of-file-fixer" "trailing-whitespace" "check-added-large-files" "check-vcs-permalinks" "check-symlinks" "destroyed-symlinks" "black" "codespell" "gitleaks")
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

# Main function
main() {
    echo -e "\n\033[0;34m================================\033[0m"
    log "STEP" "Starting Pre-commit Setup"
    echo -e "\033[0;34m================================\033[0m\n"

    check_dependencies
    setup_pre_commit_config
    # install_pre_commit_hooks_once
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

# Execute main function
main "$@"
