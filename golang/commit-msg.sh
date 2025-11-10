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
            'style',    // Changes that do not affect the meaning of the code
            'refactor', // A code change that neither fixes a bug nor adds a feature
            'perf',     // A code change that improves performance
            'test',     // Adding missing tests or correcting existing tests
            'build',    // Changes that affect the build system or external dependencies
            'ci',       // Changes to our CI configuration files and scripts
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
    echo "Created commitlint.config.js in repository root"
fi

# Get the commit message
commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Run commitlint
echo "$commit_msg" | commitlint
if [ $? -ne 0 ]; then
    # ANSI escape code for red color
    RED='\033[0;31m'
    NC='\033[0m' # No color

    echo -e "${RED}
Commit message format error. Please use the conventional commit format:

    type(scope): subject

Types:
    feat     : A new feature
    fix      : A bug fix
    docs     : Documentation only changes
    style    : Changes that do not affect code meaning
    refactor : Code change (no feat/fix)
    perf     : Performance improvement
    test     : Adding/fixing tests
    build    : Build system changes
    ci       : CI configuration changes
    chore    : Other changes
    revert   : Reverts a previous commit

Example commits:
    feat(auth): add password reset functionality
    fix(api): handle null response from server
    docs(readme): update installation instructions
${NC}"
    exit 1
fi