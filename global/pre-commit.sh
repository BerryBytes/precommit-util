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
# Generate pre-commit config if missing
#######################################
setup_pre_commit_config() {
    local file=".pre-commit-config.yaml"
    log "STEP" "Setting up pre-commit configuration"

    if [[ ! -f "$file" ]]; then
        cat > "$file" <<'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files
      - id: check-vcs-permalinks
      - id: check-symlinks
      - id: destroyed-symlinks
      - id: pretty-format-json

  - repo: https://github.com/TekWizely/pre-commit-golang
    rev: v1.0.0-rc.1
    hooks:
      - id: go-fmt
        args: [-w]
      - id: go-mod-tidy           # Ensure go.mod & go.sum are tidy

  - repo: https://github.com/psf/black
    rev: 23.9.1
    hooks:
      - id: black
        args: [--line-length=88]
  # ✅ Import sorter (runs before Black)
  - repo: https://github.com/PyCQA/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: ["--profile=black"]

  # ✅ Linter (flake8 for code quality)
  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
        args:
          - --max-line-length=88
          - --extend-ignore=E203,W503
        additional_dependencies:
          - flake8-bugbear
          - flake8-comprehensions
          - flake8-docstrings
  # ✅ Static code analysis for Python (pylint optional)
  - repo: https://github.com/pycqa/pylint
    rev: v3.2.6
    hooks:
      - id: pylint
        args: ["--disable=C0114,C0115,C0116"] 
        additional_dependencies:
          - pylint-django
          - pylint-flask

  - repo: https://github.com/terraform-docs/terraform-docs
    rev: "v0.16.0"
    hooks:
      - id: terraform-docs-go
        args: ["markdown", "table", "--output-file", "README.md", "./"]  

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: "v1.74.1"
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_tfsec

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
    "indentation": 2,
    "string-quotes": "single",
    "no-duplicate-selectors": true,
    "color-hex-case": "lower",
    "color-hex-length": "short",
    "selector-no-qualifying-type": true,
    "selector-max-id": 0,
    "selector-combinator-space-after": "always"
  }
}'
    
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



main() {
    echo -e "\n\033[0;34m================================\033[0m"
    log "STEP" "Starting Pre-commit Checks"
    echo -e "\033[0;34m================================\033[0m\n"

    check_dependencies
    # install_black
    # install_prettier
    # format_files
    setup_pre_commit_config
    install_pre_commit_hooks
    # run_formatting_hooks

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