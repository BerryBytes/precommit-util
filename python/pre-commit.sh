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

}

# # Install Black and pre-commit
# install_black() {
#     log "STEP" "Installing Black and Pre-commit"
#     if ! pip install black pre-commit; then
#         log "ERROR" "Failed to install Black and pre-commit. Ensure Python and pip are correctly set up."
#         exit 1
#     fi
#     log "INFO" "Black and pre-commit installed successfully."
# }

# Set up pre-commit configuration
setup_pre_commit_config() {
    log "STEP" "Setting Up Pre-commit Config"
    local pre_commit_config=".pre-commit-config.yaml"
    
    if [ -f "$pre_commit_config" ]; then
      log "INFO" "Existing $pre_commit_config found, skipping creation"
      return 0
    fi
    # # Detect Python version dynamically
    # local python_version
    # python_version=$(python3 -V | awk '{print $2}' | cut -d. -f1-2)

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
        files: ^.*\.(py|c|h|md|rst|yml|go|sh|sql|tf|yaml)$
        args: ["--ignore-words-list", "hist,nd"]
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]
  
EOF

    log "INFO" "Pre-commit config created at $pre_commit_config."
}

run_formatting_hooks() {
    log "STEP" "Running Formatting Checks"
    pre-commit install || { log "ERROR" "Failed to install pre-commit hooks"; return 1; }
    pre-commit install --hook-type commit-msg || { log "ERROR" "Failed to install commit-msg hook"; return 1; 

    
    local formatting_hooks=("conventional-pre-commit" "end-of-file-fixer" "check-yaml" "check-added-large-files" "black" "codespell" "gitleaks")
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


# Main function
main() {
    echo -e "\n\033[0;34m================================\033[0m"
    log "STEP" "Starting Pre-commit Checks"
    echo -e "\033[0;34m================================\033[0m\n"

    check_dependencies
    # install_black
    setup_pre_commit_config
    run_formatting_hooks
    # run_security_checks

    echo -e "\n\033[0;32m================================\033[0m"
    log "INFO" "All checks completed successfully! ✨"
    echo -e "\033[0;32m================================\033[0m\n"
}

# Execute main function
main "$@"