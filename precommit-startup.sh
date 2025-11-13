#!/bin/bash

# Display a banner
display_banner() {
    cat << 'EOF'
 _ __  _ __ ___        ___ ___  _ __ ___  _ __ ___ (_) |_ 
| '_ \| '__/ _ \_____ / __/ _ \| '_ ` _ \| '_ ` _ \| | __|
| |_) | | |  __/_____| (_| (_) | | | | | | | | | | | | |_ 
| .__/|_|  \___|      \___\___/|_| |_| |_|_| |_| |_|_|\__|
|_|                                                       
EOF
}

# Detect the operating system
detect_os() {
    local os=$(uname -s)
    case "$os" in
        Linux*)
            echo "Linux"
            ;;
        Darwin*)
            echo "macOS"
            ;;
        *)
            echo "Unsupported"
            return 1
            ;;
    esac
}

# Main function to display and handle pre-commit hook selection
main() {
    # Print banner
    display_banner
    echo -e "\n"

    # Detect OS
    OS_TYPE=$(detect_os)
    if [ $? -ne 0 ]; then
        echo "Unsupported operating system"
        exit 1
    fi

    echo "Detected Operating System: $OS_TYPE"
    echo -e "\n"

    # Display full menu options
    while true; do
        echo "Pre-Commit Hooks Installation Menu"
        echo "=================================="
        echo "[1] Global pre-commit hooks"
        echo "[2] Golang pre-commit hooks"
        echo "[3] Python pre-commit hooks"
        echo "[4] Terraform pre-commit hooks"
        echo "[5] Typescript pre-commit hooks"
        echo "[6] Exit"
        echo -e "\n"

        # Prompt for choice
        read -p "Enter your choice (1-5): " choice

        # Process the choice
        case "$choice" in
            1)
                echo -e "\nProceeding with Global pre-commit hooks installation...\n"
                # Add your global hooks installation logic here
                bash "./global/main.sh"
                break
                ;;
            2)
                echo -e "\nProceeding with Golang pre-commit hooks installation...\n"
                # Add your Golang hooks installation logic here
                bash "./golang/main.sh"
                break
                ;;
            3)
                echo -e "\nProceeding with Python pre-commit hooks installation...\n"
                # Add your Python hooks installation logic here
                bash "./python/main.sh"
                break
                ;;
            4)
                echo -e "\nProceeding with Terraform pre-commit hooks installation...\n"
                # Add your Terraform hooks installation logic here
                bash "./terraform/main.sh"
                break
                ;;
            5)
                echo -e "\nProceeding with Typescript pre-commit hooks installation...\n"
                # Add your Typescript hooks installation logic here
                bash "./typescript/main.sh"
                break
                ;;
            6)
                echo "Exiting pre-commit hooks installation..."  
                exit 0
                ;;
            *)
                echo -e "\nInvalid choice. Please try again.\n"
                # Continue the loop to show menu again
                ;;
        esac
    done

    echo -e "\nPre-commit hooks installation process completed.\n"
}

# Run the main function
main 