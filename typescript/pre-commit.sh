#!/usr/bin/env bash
#
# Complete Pre-commit Setup Script for Node.js/TypeScript Projects
# Includes all configs, dependencies, and hooks
#

set -euo pipefail

############################################
# Configuration
############################################
SCRIPT_VERSION="2.0.0"
PROJECT_ROOT="$(pwd)"

############################################
# Color Logger
############################################
log() {
    local level=$1; shift
    local color reset='\033[0m'
    case "$level" in
        INFO) color='\033[0;32m';;
        WARN) color='\033[1;33m';;
        ERROR) color='\033[0;31m';;
        STEP) color='\033[0;34m';;
        SUCCESS) color='\033[1;32m';;
        *) color='\033[0m';;
    esac
    echo -e "${color}[$level] $*${reset}"
}

############################################
# Dependency Check
############################################
check_dependencies() {
    log "STEP" "Checking system dependencies..."
    
    local deps=(git node npm)
    local missing=()

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if ((${#missing[@]})); then
        log "ERROR" "Missing required dependencies: ${missing[*]}"
        log "INFO" "Please install: ${missing[*]}"
        exit 1
    fi

    # Check for package.json
    if [[ ! -f "package.json" ]]; then
        log "WARN" "No package.json found. Creating one..."
        npm init -y
    fi

    log "INFO" "✅ All system dependencies available"
}

############################################
# Install NPM Dependencies
############################################
install_npm_dependencies() {
    log "STEP" "Installing npm dev dependencies..."
    
    local packages=(
        "pre-commit"
        "@commitlint/cli@^18.0.0"
        "@commitlint/config-conventional@^18.0.0"
        "eslint@^8.57.0"
        "@typescript-eslint/parser@^6.0.0"
        "@typescript-eslint/eslint-plugin@^6.0.0"
        "prettier@^3.3.3"
        "eslint-config-prettier@^9.0.0"
        "eslint-plugin-prettier@^5.0.0"
        "stylelint@^15.10.3"
        "stylelint-config-standard@^34.0.0"
        "stylelint-config-prettier@^9.0.5"
        "typescript@^5.0.0"
    )

    # Check if packages are already installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        local pkg_name="${pkg%%@*}"
        if ! npm list "$pkg_name" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if ((${#to_install[@]})); then
        log "INFO" "Installing: ${to_install[*]}"
        npm install --save-dev "${to_install[@]}"
    else
        log "INFO" "All npm dependencies already installed"
    fi

    log "SUCCESS" "✅ NPM dependencies ready"
}

############################################
# Create TypeScript Config
############################################
create_tsconfig() {
    local config_file="tsconfig.json"
    
    if [[ -f "$config_file" ]]; then
        log "INFO" "⏭️  $config_file already exists, skipping..."
        return
    fi

    log "STEP" "Creating $config_file..."
    
    cat > "$config_file" <<'JSON'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "moduleResolution": "node",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.spec.ts", "**/*.test.ts"]
}
JSON

    log "INFO" "✅ Created $config_file"
}

############################################
# Create ESLint Config
############################################
create_eslint_config() {
    local config_file=".eslintrc.json"
    
    if [[ -f "$config_file" ]] || [[ -f "eslint.config.js" ]] || [[ -f ".eslintrc.js" ]]; then
        log "INFO" "⏭️  ESLint config already exists, skipping..."
        return
    fi

    log "STEP" "Creating $config_file..."
    
    cat > "$config_file" <<'JSON'
{
  "root": true,
  "env": {
    "node": true,
    "es2020": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:prettier/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": 2020,
    "sourceType": "module",
    "project": "./tsconfig.json"
  },
  "plugins": ["@typescript-eslint"],
  "rules": {
    "no-console": "warn",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/no-explicit-any": "warn",
    "prettier/prettier": "error"
  },
  "ignorePatterns": ["dist", "node_modules", "*.config.js"]
}
JSON

    log "INFO" "✅ Created $config_file"
}

############################################
# Create Prettier Config
############################################
create_prettier_config() {
    local config_file=".prettierrc"
    
    if [[ -f "$config_file" ]] || [[ -f ".prettierrc.json" ]] || [[ -f "prettier.config.js" ]]; then
        log "INFO" "⏭️  Prettier config already exists, skipping..."
        return
    fi

    log "STEP" "Creating $config_file..."
    
    cat > "$config_file" <<'JSON'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "arrowParens": "always",
  "endOfLine": "lf"
}
JSON

    # Create .prettierignore
    cat > ".prettierignore" <<'IGNORE'
node_modules
dist
build
coverage
*.min.js
*.min.css
package-lock.json
yarn.lock
pnpm-lock.yaml
IGNORE

    log "INFO" "✅ Created $config_file and .prettierignore"
}

############################################
# Create Stylelint Config
############################################
create_stylelint_config() {
    local config_file=".stylelintrc.json"
    
    if [[ -f "$config_file" ]] || [[ -f "stylelint.config.js" ]]; then
        log "INFO" "⏭️  Stylelint config already exists, skipping..."
        return
    fi

    log "STEP" "Creating $config_file..."
    
    cat > "$config_file" <<'JSON'
{
  "extends": [
    "stylelint-config-standard",
    "stylelint-config-prettier"
  ],
  "rules": {
    "selector-class-pattern": null,
    "custom-property-pattern": null,
    "no-descending-specificity": null,
    "declaration-empty-line-before": null
  }
}
JSON

    log "INFO" "✅ Created $config_file"
}

############################################
# Create Commitlint Config
############################################
create_commitlint_config() {
    local config_file="commitlint.config.js"
    
    if [[ -f "$config_file" ]]; then
        log "INFO" "⏭️  $config_file already exists, skipping..."
        return
    fi

    log "STEP" "Creating $config_file..."
    
    cat > "$config_file" <<'JS'
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation only
        'style',    // Code style (formatting, missing semicolons, etc)
        'refactor', // Code refactoring
        'perf',     // Performance improvement
        'test',     // Adding or updating tests
        'chore',    // Maintenance tasks
        'ci',       // CI/CD changes
        'build',    // Build system changes
        'revert',   // Revert a previous commit
      ],
    ],
    'subject-case': [0],
  },
};
JS

    log "INFO" "✅ Created $config_file"
}

############################################
# Create Pre-commit Config
############################################
create_precommit_config() {
    local config_file=".pre-commit-config.yaml"

    log "STEP" "Creating $config_file..."

    cat > "$config_file" <<'YAML'
repos:
  # Basic file hygiene checks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-yaml
        args: ['--unsafe']  # Allow custom tags
      - id: check-json
      - id: check-toml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: check-case-conflict
      - id: mixed-line-ending

  # Gitleaks - Secret scanning
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks

  # TypeScript Type Checking
  - repo: local
    hooks:
      - id: tsc-check
        name: TypeScript Type Check
        entry: npx tsc --noEmit
        language: system
        types: [ts, tsx]
        pass_filenames: false

  # Prettier - Code formatter
  - repo: local
    hooks:
      - id: prettier
        name: Prettier Format
        entry: npx prettier --write --ignore-unknown
        language: system
        types_or: [javascript, jsx, ts, tsx, json, yaml, css, scss, html, markdown]

  # ESLint - Linting for JavaScript & TypeScript
  - repo: local
    hooks:
      - id: eslint
        name: ESLint
        entry: npx eslint --fix --max-warnings=0
        language: system
        types_or: [javascript, jsx, ts, tsx]
        files: \.(js|jsx|ts|tsx)$

  # Stylelint - CSS/SCSS Linting
  - repo: local
    hooks:
      - id: stylelint
        name: Stylelint
        entry: npx stylelint --fix
        language: system
        files: \.(css|scss|sass|less)$

  # Commitlint - Conventional commit messages
  - repo: https://github.com/alessandrojcm/commitlint-pre-commit-hook
    rev: v9.18.0
    hooks:
      - id: commitlint
        stages: [commit-msg]
        additional_dependencies: ['@commitlint/config-conventional@^18.0.0']
YAML

    log "SUCCESS" "✅ Created $config_file"
}

############################################
# Install Pre-commit Hooks
############################################
install_precommit_hooks() {
    log "STEP" "Installing pre-commit hooks..."

    # Install pre-commit if not available
    if ! command -v pre-commit &>/dev/null; then
        log "INFO" "Installing pre-commit..."
        if command -v pip3 &>/dev/null; then
            pip3 install pre-commit
        elif command -v pip &>/dev/null; then
            pip install pre-commit
        else
            log "ERROR" "pip not found. Please install Python and pip first."
            log "INFO" "Visit: https://pre-commit.com/#install"
            exit 1
        fi
    fi

    # Install hooks
    pre-commit install --install-hooks
    pre-commit install --hook-type commit-msg
    
    log "SUCCESS" "✅ Pre-commit hooks installed"
}

############################################
# Create .gitignore
############################################
update_gitignore() {
    local gitignore=".gitignore"
    
    log "STEP" "Updating $gitignore..."
    
    # Create if doesn't exist
    if [[ ! -f "$gitignore" ]]; then
        touch "$gitignore"
    fi

    # Add common ignores if not present
    local patterns=(
        "node_modules/"
        "dist/"
        "build/"
        "coverage/"
        ".env"
        ".env.local"
        "*.log"
        ".DS_Store"
        "*.swp"
        "*.swo"
    )

    for pattern in "${patterns[@]}"; do
        if ! grep -qF "$pattern" "$gitignore"; then
            echo "$pattern" >> "$gitignore"
        fi
    done

    log "INFO" "✅ Updated $gitignore"
}

############################################
# Add NPM Scripts
############################################
add_npm_scripts() {
    log "STEP" "Adding helpful npm scripts to package.json..."
    
    # Using npx to add scripts without complex JSON manipulation
    local scripts=(
        "lint:npx eslint . --ext .js,.jsx,.ts,.tsx"
        "lint:fix:npx eslint . --ext .js,.jsx,.ts,.tsx --fix"
        "format:npx prettier --write ."
        "format:check:npx prettier --check ."
        "type-check:npx tsc --noEmit"
        "style:npx stylelint '**/*.{css,scss,sass,less}'"
        "style:fix:npx stylelint '**/*.{css,scss,sass,less}' --fix"
        "precommit:pre-commit run --all-files"
    )

    log "INFO" "Add these scripts to your package.json manually:"
    echo ""
    echo '"scripts": {'
    for script in "${scripts[@]}"; do
        local name="${script%%:*}"
        local cmd="${script#*:}"
        echo "  \"$name\": \"$cmd\","
    done
    echo "}"
    echo ""
}

############################################
# Run Initial Check
############################################
run_initial_check() {
    log "STEP" "Running initial pre-commit check..."
    
    if pre-commit run --all-files; then
        log "SUCCESS" "✅ All pre-commit checks passed!"
    else
        log "WARN" "⚠️  Some checks failed. This is normal for first run."
        log "INFO" "Files have been auto-fixed. Review changes and commit."
    fi
}

############################################
# Print Summary
############################################
print_summary() {
    cat <<'SUMMARY'

╔════════════════════════════════════════════════════════════╗
║                  🎉 SETUP COMPLETE! 🎉                     ║
╚════════════════════════════════════════════════════════════╝

📦 Installed Tools:
  ✅ Pre-commit hooks
  ✅ ESLint (JavaScript/TypeScript linting)
  ✅ Prettier (Code formatting)
  ✅ Stylelint (CSS/SCSS linting)
  ✅ TypeScript type checking
  ✅ Commitlint (Conventional commits)
  ✅ Gitleaks (Secret scanning)

📝 Configuration Files Created:
  • .pre-commit-config.yaml
  • tsconfig.json
  • .eslintrc.json
  • .prettierrc
  • .stylelintrc.json
  • commitlint.config.js

🚀 Usage:
  • Hooks run automatically on git commit
  • Run manually: npm run precommit
  • Skip hooks (emergency): git commit --no-verify

🔧 Useful Commands:
  npm run lint          # Run ESLint
  npm run format        # Format with Prettier
  npm run type-check    # TypeScript check
  pre-commit run --all-files  # Run all hooks manually

💡 Commit Message Format:
  type(scope): subject
  
  Examples:
  feat(api): add user authentication
  fix(ui): resolve button alignment issue
  docs: update README with setup instructions

📚 Documentation:
  • Pre-commit: https://pre-commit.com/
  • ESLint: https://eslint.org/
  • Prettier: https://prettier.io/
  • Commitlint: https://commitlint.js.org/

SUMMARY
}

############################################
# MAIN EXECUTION
############################################
main() {
    echo ""
    log "STEP" "╔════════════════════════════════════════════════════╗"
    log "STEP" "║   Pre-commit Setup Script v${SCRIPT_VERSION}              ║"
    log "STEP" "╚════════════════════════════════════════════════════╝"
    echo ""

    check_dependencies
    install_npm_dependencies
    
    echo ""
    log "INFO" "Creating configuration files..."
    create_tsconfig
    create_eslint_config
    create_prettier_config
    create_stylelint_config
    create_commitlint_config
    create_precommit_config
    update_gitignore
    
    echo ""
    install_precommit_hooks
    
    echo ""
    add_npm_scripts
    
    echo ""
    run_initial_check
    
    echo ""
    print_summary
}

# Run main function
main "$@"