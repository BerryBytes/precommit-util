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

    # Ensure wget, curl, and tar are installed
    for cmd in wget curl tar; do
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
    if ! grep -q '## ADF' "$shell_config"; then
        {
            echo ""
            echo "## ADF"
            echo 'export PATH="$HOME/bin:$PATH"'
            echo 'export ASDF_DATA_DIR="$HOME/.asdf"'
            echo 'export PATH="$ASDF_DATA_DIR/shims:$PATH"'
        } >> "$shell_config"
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
            nodejs) plugin_repo="https://github.com/asdf-vm/asdf-nodejs.git" ;;
            golang) plugin_repo="https://github.com/asdf-community/asdf-golang.git" ;;
            gitleaks) plugin_repo="https://github.com/jmcvetta/asdf-gitleaks.git" ;;
            terraform) plugin_repo="https://github.com/asdf-community/asdf-hashicorp.git" ;;
            tflint) plugin_repo="https://github.com/skyzyx/asdf-tflint.git" ;;
            tfsec) plugin_repo="https://github.com/woneill/asdf-tfsec.git" ;;
            terraform-docs) plugin_repo="https://github.com/looztra/asdf-terraform-docs.git" ;;
            pre-commit) plugin_repo="https://github.com/jonathanmorley/asdf-pre-commit.git" ;;
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
            echo "Check available versions with: asdf list all $tool"
            return 1
        }
    fi

    asdf set "$tool" "$version"
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
    "pre-commit:3.3.3"
    "tflint:0.59.1"
    "tfsec:1.28.1"
    "terraform-docs:0.16.0"
)

# List of optional tools (including Terraform for custom version input)
declare -a optional_tools=(
    "golang"
    "terraform"
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

# Interactive installation for optional tools (including Terraform)
echo -e "\nOptional tools setup:"
for tool in "${optional_tools[@]}"; do
    read -p "Do you want to install $tool? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        # echo "Checking available versions for $tool..."
        # asdf list all "$tool" | tail -n 10
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
