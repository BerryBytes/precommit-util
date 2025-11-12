#!/usr/bin/env bash
#
# Universal Pre-commit Setup Script
# Supports Node.js, TypeScript, JavaScript, CSS and more
#

set -euo pipefail

############################################
# Logger Function
############################################
log() {
    local level=$1; shift
    local color reset='\033[0m'
    case "$level" in
        INFO) color='\033[0;32m';;
        WARN) color='\033[1;33m';;
        ERROR) color='\033[0;31m';;
        STEP) color='\033[0;34m';;
        *) color='\033[0m';;
    esac
    echo -e "${color}[$level] $*${reset}"
}

############################################
# Dependency Check
############################################
check_dependencies() {
    local deps=(pre-commit npx)
    local missing=()

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if ((${#missing[@]})); then
        log "ERROR" "Missing dependencies: ${missing[*]}"
        log "INFO" "Install them using asdf or npm (e.g., 'npm i -g pre-commit')."
        exit 1
    fi

    if ! command -v commitlint &>/dev/null; then
        log "INFO" "Installing commitlint globally..."
        npm install -g @commitlint/cli @commitlint/config-conventional
    fi
}

############################################
# Generate ESLint Config if Missing
############################################
setup_eslint_config() {
    local eslint_config=".eslintrc.json"
    if [ -f "$eslint_config" ]; then
        log "INFO" "Existing $eslint_config found — skipping creation."
        return
    fi

    log "STEP" "Creating default $eslint_config..."
    cat > "$eslint_config" <<'ESLINT_JSON'
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier"
  ],
  "plugins": ["@typescript-eslint"],
  "rules": {
    "no-unused-vars": "warn",
    "no-console": "off",
    "@typescript-eslint/no-explicit-any": "off"
  }
}
ESLINT_JSON
    log "INFO" "✅ .eslintrc.json created successfully."
}

############################################
# Generate Stylelint Config if Missing
############################################
setup_stylelint_config() {
    local stylelint_config=".stylelintrc.json"
    if [ -f "$stylelint_config" ]; then
        log "INFO" "Existing $stylelint_config found — skipping creation."
        return
    fi

    log "STEP" "Creating default $stylelint_config..."
    cat > "$stylelint_config" <<'STYLELINT_JSON'
{
  "extends": ["stylelint-config-standard", "stylelint-config-prettier"],
  "rules": {
    "color-hex-case": "lower",
    "indentation": 2,
    "no-empty-source": null
  }
}
STYLELINT_JSON
    log "INFO" "✅ .stylelintrc.json created successfully."
}

############################################
# Generate Pre-commit Config
############################################
setup_pre_commit_config() {
    local config_file=".pre-commit-config.yaml"

    log "STEP" "Creating/Updating $config_file"
    cat > "$config_file" <<'YAML'
repos:
  # Basic file hygiene checks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files

  # Gitleaks - Secret scanning
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]

  # Prettier - Code formatter for JS/TS/CSS/JSON
  - repo: https://github.com/prettier/prettier
    rev: "3.3.3"
    hooks:
      - id: prettier
        name: prettier-format
        entry: npx prettier --write
        language: system
        types_or: [javascript, ts, tsx, json, yaml, css, scss, html, markdown]

  # ESLint - Linting for JavaScript & TypeScript
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v9.14.0
    hooks:
      - id: eslint
        name: eslint-lint
        entry: npx eslint
        language: system
        types_or: [javascript, ts, tsx]
        args: ["--max-warnings=0"]

  # Stylelint - For CSS/SCSS/Less
  - repo: https://github.com/thibaudcolas/pre-commit-stylelint
    rev: v15.10.3
    hooks:
      - id: stylelint
        name: stylelint-check
        entry: npx stylelint
        language: system
        files: \.(css|scss|sass|less)$
        additional_dependencies:
          - stylelint
          - stylelint-config-standard
          - stylelint-config-prettier

  # Commitlint - Conventional commit message enforcement
  - repo: https://github.com/alessandrojcm/commitlint-pre-commit-hook
    rev: v9.17.0
    hooks:
      - id: commitlint
        name: commitlint-check
        stages: [commit-msg]
        additional_dependencies:
          - "@commitlint/config-conventional"
YAML

    log "INFO" "✅ .pre-commit-config.yaml created successfully."
}

############################################
# Install Pre-commit Hooks
############################################
install_pre_commit_hooks() {
    log "STEP" "Installing pre-commit hooks..."
    pre-commit install --install-hooks
    pre-commit install --hook-type commit-msg
    log "INFO" "✅ Pre-commit hooks installed."
}

############################################
# Run Pre-commit Hooks Once
############################################
run_pre_commit_hooks() {
    log "STEP" "Running pre-commit checks on all files..."
    if pre-commit run --all-files; then
        log "INFO" "✅ All pre-commit checks passed successfully!"
    else
        log "WARN" "⚠️  Some checks failed — please fix them before committing."
        exit 1
    fi
}

############################################
# MAIN EXECUTION
############################################
main() {
    echo -e "\n\033[0;34m============================================\033[0m"
    log "STEP" "Starting Pre-commit Setup and Configuration"
    echo -e "\033[0;34m============================================\033[0m\n"

    check_dependencies
    setup_eslint_config
    setup_stylelint_config
    setup_pre_commit_config
    install_pre_commit_hooks
    run_pre_commit_hooks

    echo -e "\n\033[0;32m============================================\033[0m"
    log "INFO" "🎉 Pre-commit setup complete and verified!"
    echo -e "\033[0;32m============================================\033[0m\n"
}

main "$@"
