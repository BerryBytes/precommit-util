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
    for cmd in pre-commit gitleaks npx; do
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

    cat > "$pre_commit_config" <<EOF
repos:
  # - repo: https://github.com/compilerla/conventional-pre-commit
  #   rev: v2.1.1
  #   hooks:
  #     - id: conventional-pre-commit
  #       stages: [commit-msg]
  #       args: [feat, fix, ci, chore, test] 
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
#     # Create a basic Prettier config
#     cat > ".prettierrc" <<EOF
# {
#   "singleQuote": true,
#   "trailingComma": "es5",
#   "tabWidth": 2,
#   "semi": true,
#   "printWidth": 100,
#   "overrides": [
#     {
#       "files": "*.html",
#       "options": {
#         "parser": "html"
#       }
#     },
#     {
#       "files": "*.css",
#       "options": {
#         "parser": "css"
#       }
#     }
#   ],
#   "ignore": ["node_modules"]
# }
# EOF

#     # Create a Stylelint config
#     cat > ".stylelintrc" <<EOF
# {
#   "extends": "stylelint-config-standard",
#   "rules": {
#     "indentation": 2,
#     "string-quotes": "single",
#     "no-duplicate-selectors": true,
#     "color-hex-case": "lower",
#     "color-hex-length": "short",
#     "selector-no-qualifying-type": true,
#     "selector-max-id": 0,
#     "selector-combinator-space-after": "always"
#   }
# }
# EOF

#     # Create a basic TypeScript config
#     cat > "tsconfig.json" <<EOF
# {
#   "compilerOptions": {
#     "target": "es2020",
#     "module": "commonjs",
#     "strict": true,
#     "esModuleInterop": true,
#     "skipLibCheck": true,
#     "forceConsistentCasingInFileNames": true
#   },
#   "include": ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"],
#   "exclude": ["node_modules", "dist", "build"]
# }
# EOF

    log "INFO" "Pre-commit config and configs created."
}

run_formatting_hooks() {
    log "STEP" "Running Formatting Checks"
    pre-commit install || { log "ERROR" "Failed to install pre-commit hooks"; return 1; }
    pre-commit install --hook-type commit-msg || { log "ERROR" "Failed to install commit-msg hook"; return 1; 

    local formatting_hooks=("check-yaml" "end-of-file-fixer" "trailing-whitespace" "check-added-large-files" "prettier" "stylelint" "codespell")
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
    setup_pre_commit_config
    # pre-commit install
    run_formatting_hooks

    echo -e "\n\033[0;32m================================\033[0m"
    log "INFO" "Pre-commit Hooks Configured Successfully! ✨"
    echo -e "\033[0;32m================================\033[0m\n"
}

# Execute main function
main "$@"