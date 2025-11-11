#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

############################################
# Color-coded logging utility
############################################
log() {
    local level="$1"; shift
    local color reset='\033[0m'
    case "$level" in
        INFO)  color='\033[0;32m' ;;
        WARN)  color='\033[1;33m' ;;
        ERROR) color='\033[0;31m' ;;
        STEP)  color='\033[0;34m' ;;
        *)     color='\033[0m' ;;
    esac
    echo -e "${color}[$level] $*${reset}"
}

############################################
# Check required dependencies
############################################
check_dependencies() {
    log "STEP" "Checking dependencies..."
    local deps=("python3" "pre-commit")
    local missing=()

    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done

    if ((${#missing[@]} > 0)); then
        log "ERROR" "Missing dependencies: ${missing[*]}"
        log "INFO" "Please install the missing dependencies and try again."
        exit 1
    fi

    if ! command -v commitlint &>/dev/null; then
        log "INFO" "Installing commitlint globally..."
        npm install -g @commitlint/cli @commitlint/config-conventional
    fi
}

############################################
# Create .pre-commit-config.yaml if missing
############################################
setup_pre_commit_config() {
    local config=".pre-commit-config.yaml"
    log "STEP" "Setting up pre-commit configuration..."

    if [[ -f "$config" ]]; then
        log "INFO" "$config already exists — skipping creation."
        return
    fi

    local python_version
    python_version=$(python3 -V | awk '{print $2}' | cut -d. -f1-2)

    cat > "$config" <<'EOF'
repos:
  # ✅ Generic pre-commit hygiene
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files
      - id: check-vcs-permalinks
      - id: check-symlinks
      - id: destroyed-symlinks
      - id: detect-private-key
      - id: check-merge-conflict

  # ✅ Python code formatter
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

  # ✅ Type checking
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.10.0
    hooks:
      - id: mypy
        args: ["--ignore-missing-imports", "--strict"]

  # ✅ Security scanning (Bandit)
  - repo: https://github.com/PyCQA/bandit
    rev: 1.7.5
    hooks:
      - id: bandit
        args: ["-ll", "-r", "."]

  # ✅ Detect secrets in code
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
        args: ["detect", "--verbose"]

  # ✅ Static code analysis for Python (pylint optional)
  - repo: https://github.com/pycqa/pylint
    rev: v3.2.6
    hooks:
      - id: pylint
        args: ["--disable=C0114,C0115,C0116"]  # disable docstring warnings
        additional_dependencies:
          - pylint-django
          - pylint-flask

  # ✅ Spell checking for docs, code comments, configs
  - repo: https://github.com/codespell-project/codespell
    rev: v2.2.5
    hooks:
      - id: codespell
        files: ^.*\.(py|c|h|md|rst|yml|go|sh|sql|tf|yaml)$
        args: ["--ignore-words-list", "hist,nd,bu,maks,gir"]

  # ✅ Check for dependency vulnerabilities (pip-audit)
  - repo: https://github.com/pypa/pip-audit
    rev: v2.7.3
    hooks:
      - id: pip-audit
        args: ["--require-hashes", "--strict"]

  # ✅ Run tests automatically before committing (pytest)
  - repo: local
    hooks:
      - id: pytest
        name: pytest
        entry: pytest
        language: system
        types: [python]
        pass_filenames: false
        args: ["-q", "--disable-warnings"]

EOF

    log "INFO" "$config created successfully."
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

############################################
# Main Execution Flow
############################################
main() {
    echo -e "\n\033[0;34m================================\033[0m"
    log "STEP" "Starting Pre-commit Setup and Checks"
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