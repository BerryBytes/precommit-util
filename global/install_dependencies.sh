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

    # Ensure asdf directory is clean
    if [ -d "$HOME/.asdf" ]; then
        echo "Removing existing .asdf installation..."
        rm -rf "$HOME/.asdf" || {
            echo "Failed to remove existing .asdf directory."
            return 1
        }
    fi

    # Install asdf if not already installed
    if ! command -v asdf &>/dev/null; then
        echo "Installing asdf..."
        git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch master || {
            echo "Failed to clone asdf repository."
            return 1
        }
    fi

    # Configure asdf in the shell's config file
    if ! grep -q 'asdf.sh' "$shell_config"; then
        cat <<EOF >>"$shell_config"

# Load asdf
. "$HOME/.asdf/asdf.sh"
EOF
        if [[ "$shell_name" == "zsh" ]]; then
            cat <<EOF >>"$shell_config"

# Append completions to fpath
fpath=(${HOME}/.asdf/completions $fpath)

# Initialize completions with ZSH compinit
autoload -Uz compinit && compinit
EOF
        elif [[ "$shell_name" == "bash" ]]; then
            echo '. "$HOME/.asdf/completions/asdf.bash"' >>"$shell_config"
        fi
        echo "asdf initialization added to $shell_config."
    fi

    # Source the shell configuration to load asdf
    source "$shell_config"

    # Verify asdf installation
    if ! command -v asdf &>/dev/null; then
        echo "asdf installation or sourcing failed. Please check $shell_config."
        return 1
    fi
    echo "asdf installed and configured successfully."
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
            python) plugin_repo="https://github.com/asdf-community/asdf-python.git" ;;
            terraform) plugin_repo="https://github.com/asdf-community/asdf-hashicorp.git" ;;
            tflint) plugin_repo="https://github.com/skyzyx/asdf-tflint" ;;
            tfsec) plugin_repo="https://github.com/woneill/asdf-tfsec.git" ;;
            terraform-docs) plugin_repo="https://github.com/looztra/asdf-terraform-docs" ;;
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
    "yamlfmt:0.14.0"
    "pre-commit:3.3.3"
    "tflint:0.39.2"
    "tfsec:1.28.1"
    "terraform-docs:0.16.0"
    "golangci-lint:1.63.4"
)

# List of optional tools
declare -a optional_tools=(
    "golang"
    "python"
    "nodejs"
    "terraform"
    
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
echo "\nOptional tools setup:"
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
