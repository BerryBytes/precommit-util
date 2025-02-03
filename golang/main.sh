#!/bin/bash

# Display a message indicating this script is running
echo "Running global pre-commit hooks setup...."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to install_dependencies.sh
INSTALL_DEPENDENCIES="$SCRIPT_DIR/install_dependencies.sh"

# Install necessary dependencies
if [ -f "$INSTALL_DEPENDENCIES" ]; then
    echo "Installing dependencies..."
    source "$INSTALL_DEPENDENCIES"
else
    echo "[!] Error: $INSTALL_DEPENDENCIES not found. Skipping dependency install."
fi

# Set up Git hooks
TEMPLATE_DIR="$HOME/.git-templates/hooks"
mkdir -p "$TEMPLATE_DIR"

# cp golang/commit-msg.sh "$TEMPLATE_DIR/commit-msg"
cp golang/pre-commit.sh "$TEMPLATE_DIR/pre-commit"

chmod +x  "$TEMPLATE_DIR/pre-commit" # "$TEMPLATE_DIR/commit-msg"

## automatically enabling pre-commit on repositories
git config --global init.templateDir "$HOME/.git-templates"
echo "Git hooks set up successfully!"

