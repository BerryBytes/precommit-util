#!/usr/bin/env bash
set -euo pipefail

# Create commitlint config if it doesn't exist
if [ ! -f "$(git rev-parse --show-toplevel)/commitlint.config.js" ]; then
    cat << 'CONFIG_EOF' > "$(git rev-parse --show-toplevel)/commitlint.config.js"
module.exports = {
    extends: ['@commitlint/config-conventional'],
    rules: {
        'type-enum': [2, 'always', [
            'feat',     // A new feature  
            'fix',      // A bug fix
            'docs',     // Documentation only changes  
            'style',    // Changes that do not affect code meaning
            'refactor', // A code change that neither fixes a bug nor adds a feature
            'perf',     // A code change that improves performance
            'test',     // Adding missing tests or correcting existing tests
            'build',    // Build system or external dependencies  
            'ci',       // CI configuration changes
            'chore',    // Other changes that don't modify src or test files
            'revert',   // Reverts a previous commit
        ]],
        'type-case': [2, 'always', 'lowerCase'],
        'type-empty': [2, 'never'],
        'scope-case': [2, 'always', 'lowerCase'],
        'subject-empty': [2, 'never'],
        'subject-full-stop': [2, 'never', '.'],
        'header-max-length': [2, 'always', 72],
    },  
};
CONFIG_EOF
    echo "✅ Created commitlint.config.js in repository root"
fi

# Ensure commitlint is available
if ! command -v commitlint >/dev/null 2>&1; then
    echo "⚙️ Installing commitlint globally..."
    npm install -g @commitlint/cli @commitlint/config-conventional >/dev/null 2>&1
fi

# Read commit message
commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Run commitlint and capture output (important!)
lint_output=$(echo "$commit_msg" | commitlint 2>&1) || lint_status=$?

if [ "${lint_status:-0}" -ne 0 ]; then
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'

    echo -e "${RED}\n❌ Commit message format error detected.${NC}"
    echo -e "${YELLOW}\nCommit message must follow the Conventional Commit format:\n${NC}"
    echo -e "${YELLOW}    type(scope): subject${NC}"
    echo -e "\n${YELLOW}Types:${NC}"
    echo "    feat     : A new feature"
    echo "    fix      : A bug fix"
    echo "    docs     : Documentation only changes"
    echo "    style    : Changes that do not affect code meaning"
    echo "    refactor : Code change that neither fixes a bug nor adds a feature"
    echo "    perf     : Code change that improves performance"
    echo "    test     : Adding or correcting tests"
    echo "    build    : Changes to the build system or external dependencies"
    echo "    ci       : CI configuration or scripts"
    echo "    chore    : Other changes that don't modify src or test files"
    echo "    revert   : Reverts a previous commit"
    echo -e "\n${YELLOW}Examples:${NC}"
    echo "    feat(auth): add password reset functionality"
    echo "    fix(api): handle null server response"
    echo "    docs(readme): update installation instructions"

    echo -e "\n${RED}Commitlint output:${NC}"
    echo "$lint_output"

    echo -e "\n${RED}❗ Please fix your commit message and try again.${NC}"
    exit 1
else
    echo -e "\033[0;32m✅ Commit message passed Conventional Commit check.\033[0m"
fi
