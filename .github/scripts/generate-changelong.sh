#!/usr/bin/env bash
set -euo pipefail

# Local helper to preview changelog (does not publish)
# Requires semantic-release to be installed globally

if ! command -v semantic-release &>/dev/null; then
  echo "semantic-release not found. Install it using:"
  echo "  npm install -g semantic-release @semantic-release/changelog @semantic-release/git @semantic-release/commit-analyzer @semantic-release/release-notes-generator"
  exit 1
fi

echo "Generating changelog preview..."
npx semantic-release --no-ci --dry-run
