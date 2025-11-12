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
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files
      
  # - repo: https://github.com/eslint/eslint
  #   rev: v8.56.0
  #   hooks:
  #     - id: eslint
  #       files: \.(js|jsx|ts|tsx|html)$
  #       types: [file]
  #       additional_dependencies: 
  #         - '@typescript-eslint/parser@v5.62.0'
  #         - '@typescript-eslint/eslint-plugin@v5.62.0'
  #       args: ['--config', 'eslint.config.mjs']
        
  # - repo: https://github.com/pre-commit/mirrors-prettier
  #   rev: v3.1.0
  #   hooks:
  #     - id: prettier
  #       files: \.(js|jsx|ts|tsx|css|html|json)$
  #       types: [file]
  #       exclude: "node_modules/"

  - repo: https://github.com/thibaudcolas/pre-commit-stylelint
    rev: v15.10.3
    hooks:
      - id: stylelint
        files: \.(css|scss)$
        additional_dependencies:
          - stylelint
          - stylelint-config-standard

  # - repo: https://github.com/codespell-project/codespell
  #   rev: v2.2.5
  #   hooks:
  #     - id: codespell
  #       files: ^.*\.(py|c|h|md|rst|yml|go|sh|sql|tf|yaml|html|css|js|jsx|ts|tsx)$
  #       args: ["--ignore-words-list", "hist,nd"]
        
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]
  
EOF
    # Create a basic Prettier config
    cat > ".prettierrc" <<EOF
{
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
}
EOF

    # Create a Stylelint config
    cat > ".stylelintrc" <<EOF
{
  "extends": "stylelint-config-standard",
  "rules": {
    "indentation": 2,
    "string-quotes": "single",
    "no-duplicate-selectors": true,
    "color-hex-case": "lower",
    "color-hex-length": "short",
    "selector-no-qualifying-type": true,
    "selector-max-id": 0,
    "selector-combinator-space-after": "always"
  }
}
EOF

    # Create a basic TypeScript config
    cat > "tsconfig.json" <<EOF
{
  "compilerOptions": {
    "target": "es2020",
    "module": "commonjs",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"],
  "exclude": ["node_modules", "dist", "build"]
}
EOF

    log "INFO" "Pre-commit config and configs created."
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
# Main function
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

# Execute main function
main "$@"