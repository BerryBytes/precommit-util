#!/bin/bash

# List of directories in root that may contain pre-commit.sh
LANG_DIRS=("global" "golang" "python" "terraform" "typescript")

echo "🔍 Searching for pre-commit.sh in project folders..."

for dir in "${LANG_DIRS[@]}"; do
    script_path="$dir/pre-commit.sh"

    if [[ -f "$script_path" ]]; then
        echo "➡️  Found: $script_path"

        # Create destination folder
        dest_dir="$dir/precommitFile"
        mkdir -p "$dest_dir"

        # Output file
        dest_file="$dest_dir/.pre-commit-config.yaml"

        # Extract YAML using sed
        sed -n "/cat > \"\\\$file\" <<'EOF'/,/EOF/p" "$script_path" \
          | sed '1d;$d' > "$dest_file"

        echo "   ✓ Extracted config → $dest_file"
    else
        echo "⚠️  No pre-commit.sh found in $dir — skipping."
    fi
done

echo "✅ Extraction complete!"
