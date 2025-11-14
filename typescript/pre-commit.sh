#!/usr/bin/env bash

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

#######################################
# Color-coded logger
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
    local deps=("pre-commit" "gitleaks")
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
# Create config files if missing
#######################################
create_config_if_missing() {
    local file_name="$1"
    local content="$2"
    
    if [[ -f "$file_name" ]]; then
        log "INFO" "$file_name already exists — skipping creation"
    else
        log "STEP" "Creating $file_name..."
        echo "$content" > "$file_name"
        log "INFO" "$file_name created"
    fi
}

#######################################
# Setup pre-commit configuration
#######################################
setup_pre_commit_config() {
    local file=".pre-commit-config.yaml"
    log "STEP" "Setting up pre-commit configuration"

    if [[ ! -f "$file" ]]; then
        cat > "$file" <<'EOF'
repos:
  ############  ✅ Precommit hooks #############      
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files

  # - repo: https://github.com/pre-commit/mirrors-prettier
  #   rev: v3.1.0
  #   hooks:
  #     - id: prettier
  #       files: \.(js|jsx|ts|tsx|css|html|json)$
  #       types: [file]
  #       exclude: "node_modules/"
  #       args: ['--config', '.prettierrc']

  - repo: https://github.com/thibaudcolas/pre-commit-stylelint
    rev: v15.10.3
    hooks:
      - id: stylelint
        files: \.(css|scss)$
        exclude: "node_modules/"
        additional_dependencies:
          - stylelint
          - stylelint-config-standard
        args: ['--config', '.stylelintrc.json', '--fix']

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]
EOF
        log "INFO" "Pre-commit config created."
    else
        log "INFO" "$file already exists — skipping creation"
    fi

    # Create .prettierrc if missing
    create_config_if_missing ".prettierrc" '{
  "singleQuote": true,
  "trailingComma": "es5",
  "tabWidth": 2,
  "semi": true,
  "printWidth": 100,
  "overrides": [
    {
      "files": "*.html",
      "options": {
        "parser": "html"
      }
    },
    {
      "files": "*.css",
      "options": {
        "parser": "css"
      }
    }
  ],
  "ignore": ["node_modules"]
}'

    # Create .stylelintrc.json if missing
  create_config_if_missing ".stylelintrc.json" '{
  "extends": "stylelint-config-standard",
  "rules": {
    "no-duplicate-selectors": true,
    "color-hex-length": "short",
    "selector-no-qualifying-type": true,
    "selector-max-id": 0
  }
}'
}

############################################
# Install pre-commit hooks
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
# Run all pre-commit hooks once
############################################
run_pre_commit_hooks() {
    log "STEP" "Running all pre-commit checks (single pass)..."
    
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
