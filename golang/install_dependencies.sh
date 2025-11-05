#!/bin/bash

# Function to detect the shell and configure it for asdf
detect_shell_and_configure_asdf() {
    local shell_name shell_config
    shell_name=$(basename "$SHELL")

    case "$shell_name" in
        zsh) shell_config="$HOME/.zshrc" ;;
        bash) shell_config="$HOME/.bashrc" ;;
        *)
            echo "Unsupported shell: $shell_name. Please configure asdf manually."
            return 1
            ;;
    esac

    echo "Detected shell: $shell_name. Configuring asdf for $shell_config."

    # Ensure wget and tar are installed
    for cmd in wget tar; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "$cmd not found. Installing $cmd..."
            if command -v apt-get &>/dev/null; then
                sudo apt-get update -y && sudo apt-get install -y "$cmd"
            elif command -v yum &>/dev/null; then
                sudo yum install -y "$cmd"
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y "$cmd"
            elif command -v apk &>/dev/null; then
                sudo apk add --no-cache "$cmd"
            else
                echo "No supported package manager found. Please install $cmd manually."
                return 1
            fi
        fi
    done

    # Ensure $HOME/bin exists
    mkdir -p "$HOME/bin"

    # Remove any old installation
    if [ -d "$HOME/.asdf" ]; then
        echo "Removing existing .asdf directory..."
        rm -rf "$HOME/.asdf"
    fi

    # Detect OS and Architecture
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    # Normalize architecture name
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
    esac

    local version="v0.18.0"
    local tarball="asdf-${version}-${os}-${arch}.tar.gz"
    local download_url="https://github.com/asdf-vm/asdf/releases/download/${version}/${tarball}"

    echo "Downloading ASDF ${version} for ${os}-${arch}..."
    wget -q "$download_url" -O "/tmp/${tarball}" || {
        echo "Failed to download ${download_url}"
        return 1
    }

    echo "Extracting ${tarball} to $HOME/bin..."
    tar -xzf "/tmp/${tarball}" -C "$HOME/bin" || {
        echo "Failed to extract asdf binary."
        return 1
    }

    # Ensure binary is executable
    chmod +x "$HOME/bin/asdf" 2>/dev/null || true

    # Configure PATH and environment variables in shell config
    if ! grep -q 'export PATH="\$HOME/bin:\$PATH"' "$shell_config"; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_config"
    fi

    if ! grep -q 'export ASDF_DATA_DIR=' "$shell_config"; then
        echo 'export ASDF_DATA_DIR="$HOME/.asdf"' >> "$shell_config"
    fi

    if ! grep -q 'export PATH="\$ASDF_DATA_DIR/shims:\$PATH"' "$shell_config"; then
        echo 'export PATH="$ASDF_DATA_DIR/shims:$PATH"' >> "$shell_config"
    fi

    echo "asdf configuration added to $shell_config."
    source "$shell_config"

    # Verify installation
    if ! command -v asdf &>/dev/null; then
        echo "asdf installation or PATH setup failed. Please check $shell_config."
