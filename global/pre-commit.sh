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
    for cmd in pre-commit gitleaks npx go; do
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
    # Detect Python version dynamically
    local python_version
    python_version=$(python3 -V | awk '{print $2}' | cut -d. -f1-2)

    # if [ ! -f "$pre_commit_config" ]; then
        cat > "$file" <<'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
        args: ["--allow-multiple-documents"]
      - id: end-of-file-fixer
        args: ["--check"]  # only checks, does not modify
      - id: trailing-whitespace
        args: ["--check"]  # only checks, does not modify
      - id: check-added-large-files
      - id: check-vcs-permalinks
      - id: check-symlinks
      - id: destroyed-symlinks
      - id: pretty-format-json
        args: ["--no-autofix"]  # prevents auto-formatting; reports instead

  - repo: https://github.com/dnephin/pre-commit-golang
    rev: v0.5.0
    hooks:
      - id: go-fmt
        args: ["--dry-run", "--check"]  # do not auto-format
      - id: go-imports
        args: ["--dry-run", "--check"]
      - id: no-go-testing
      - id: go-unit-tests

  # - repo: https://github.com/golangci/golangci-lint
  #   rev: v1.55.2
  #   hooks:
  #     - id: golangci-lint
  #       args: ["run", "--fix=false"]

  - repo: https://github.com/psf/black
    rev: 23.9.1
    hooks:
      - id: black
        args: ["--check", "--diff", "--line-length=88"]  # check mode only
        language_version: python${python_version}

  - repo: https://github.com/terraform-docs/terraform-docs
    rev: "v0.16.0"
    hooks:
      - id: terraform-docs-go
        args: ["markdown", "table", "--output-file", "README.md", "./", "--check"]  # show diff only

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: "v1.74.1"
    hooks:
      - id: terraform_fmt
        args: ["--check"]  # report formatting issues
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_tfsec

  # - repo: https://github.com/pre-commit/mirrors-prettier
  #   rev: v3.1.0
  #   hooks:
  #     - id: prettier
  #       args: ["--check"]
  #       files: \.(js|jsx|ts|tsx|css|html|json)$
  #       types: [file]
  #       exclude: "node_modules/"

  # - repo: https://github.com/thibaudcolas/pre-commit-stylelint
  #   rev: v15.10.3
  #   hooks:
  #     - id: stylelint
  #       files: \.(css|scss)$
  #       args: ["--formatter", "verbose"]
  #       additional_dependencies:
  #         - stylelint
  #         - stylelint-config-standard

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
        verbose: true

  
  
EOF

         log "INFO" "$file created successfully."
    
}

run_formatting_hooks() {
    log "STEP" "Running Formatting Checks"
    pre-commit install || { log "ERROR" "Failed to install pre-commit hooks"; return 1; 
    # pre-commit install --hook-type commit-msg || { log "ERROR" "Failed to install commit-msg hook"; return 1; 

    local formatting_hooks=("check-yaml" "end-of-file-fixer" "trailing-whitespace" "check-added-large-files" "check-vcs-permalinks" "go-fmt"
    "check-symlinks" "destroyed-symlinks" "black" "go-imports" "codespell" "no-go-testing" "terraform_fmt" "terraform_validate"
    "terraform_tflint" "terraform_tfsec" "go-unit-tests" "gitleaks" "prettier" "stylelint")
    
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
    log "STEP" "Starting Pre-commit Checks"
    echo -e "\033[0;34m================================\033[0m\n"

    check_dependencies
    # install_black
    # install_prettier
    # format_files
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