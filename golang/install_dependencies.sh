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

    # Ensure wget is installed
    if ! command -v wget &>/dev/null; then
        echo "wget not found. Installing wget..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -y && sudo apt-get install -y wget
        elif command -v yum &>/dev/null; then
            sudo yum install -y wget
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y wget
        elif command -v apk &>/dev/null; then
            sudo apk add --no-cache wget
        else
            echo "No supported package manager found. Please install wget manually."
            return 1
        fi
    fi

    # Ensure $HOME/bin exists
    mkdir -p "$HOME/bin"

    # Remove any old asdf binary or installation
    if [ -f "$HOME/bin/asdf" ]; then
        echo "Removing existing asdf binary..."
        rm -f "$HOME/bin/asdf"
    fi
    if [ -d "$HOME/.asdf" ]; then
        echo "Removing existing .asdf directory..."
        rm -rf "$HOME/.asdf"
    fi

    # Download the new asdf binary
    echo "Downloading asdf v0.16.0 binary..."
    wget https://github.com/asdf-vm/asdf/releases/download/v0.16.0/asdf-linux-amd64 -O "$HOME/bin/asdf" || {
        echo "Failed to download asdf binary."
        return 1
    }

    chmod +x "$HOME/bin/asdf"

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
        return 1
    fi

    echo "asdf installed successfully."
    asdf --version
    asdf reshim
    echo "asdf configured and ready to use."
}

# Function to install an asdf tool and its version
install_tool_with_asdf() {
    local tool="$1" version="$2"

    # Add asdf plugin if not present
    if ! asdf plugin list | grep -q "^$tool$"; then
        local plugin_repo
        case "$tool" in
            nodejs) plugin_repo="https://github.com/asdf-vm/asdf-nodejs" ;;
            golang) plugin_repo="https://github.com/asdf-community/asdf-golang" ;;
            golangci-lint) plugin_repo="https://github.com/hypnoglow/asdf-golangci-lint.git" ;;
            yamlfmt) plugin_repo="https://github.com/kachick/asdf-yamlfmt" ;;
            gitleaks) plugin_repo="https://github.com/jmcvetta/asdf-gitleaks" ;;
            pre-commit) plugin_repo="git@github.com:jonathanmorley/asdf-pre-commit.git" ;;
            *)
                echo "No plugin URL specified for $tool."
                return 1
                ;;
        esac
        asdf plugin add "$tool" "$plugin_repo" || {
            echo "Failed to add plugin for $tool."
            return 1
        }
    fi

    # Install the specified version
    if ! asdf list "$tool" | grep -q "^$version$"; then
        echo "Installing $tool version $version..."
        asdf install "$tool" "$version" || {
            echo "Failed to install $tool version $version."
            return 1
        }
    fi
    asdf global "$tool" "$version"
    echo "$tool version $version installed and set globally."
}

# Function to update the .tool-versions file
update_tool_versions_file() {
    local tool="$1" version="$2"
    grep -v "^$tool " "$HOME/.tool-versions" > /tmp/.tool-versions.tmp || true
    echo "$tool $version" >> /tmp/.tool-versions.tmp
    mv /tmp/.tool-versions.tmp "$HOME/.tool-versions"
}

# Install and configure asdf
if ! detect_shell_and_configure_asdf; then
    echo "Please restart the terminal and re-run the script."
    exit 1
fi

# Initialize/reset .tool-versions
> "$HOME/.tool-versions"

# List of mandatory tools and their versions
declare -a mandatory_tools=(
    "gitleaks:8.21.0"
    "yamlfmt:latest"
    "pre-commit:3.3.3"
    "golangci-lint:1.63.4"
)

# List of optional tools
declare -a optional_tools=(
    "golang"
    "nodejs"
)

# Install mandatory tools without user interaction
echo "Installing mandatory tools..."
for tool_entry in "${mandatory_tools[@]}"; do
    tool="${tool_entry%%:*}"
    version="${tool_entry##*:}"
    if install_tool_with_asdf "$tool" "$version"; then
        update_tool_versions_file "$tool" "$version"
    else
        echo "Failed to install $tool. Skipping..."
    fi
done

# Install optional tools with user interaction
echo -e "\nOptional tools setup:"
for tool in "${optional_tools[@]}"; do
    read -p "Do you want to install $tool? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        read -p "Enter the preferred version for $tool: " version
        if install_tool_with_asdf "$tool" "$version"; then
            update_tool_versions_file "$tool" "$version"
        else
            echo "Failed to install $tool. Skipping..."
        fi
    else
        echo "Skipping $tool installation."
    fi
done

# Summary
echo -e "\nInstallation Summary:"
if [ -f "$HOME/.tool-versions" ]; then
    cat "$HOME/.tool-versions"
else
    echo "No tools were successfully installed."
fi
