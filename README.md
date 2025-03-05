# Pre-commit Automation Tools 🔧
A comprehensive suite of Git hooks and development environment setup tools that enforce code quality, formatting standards, and conventional commits across your projects.

## Table of Contents 📋

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Skipping Pre-commit Hooks](#skipping-pre-commit-hooks)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)



## Overview 
This toolkit provides automated setup and enforcement of development best practices through:

- Code formatting and linting
- Security scanning
- Conventional commit message enforcement
- Development environment standardization across multiple projects

## OS Requirements
- **Linux:** Above Linux 4.16.10-300.fc28.x86_64 x86_64
- **MacOS:** Above Mac OS X 10.7 Lion

## Prerequisites
- ```sudo``` may be required depending on your system configuration 
- git (version control)
## Installation Tools
The following tools will be automatically installed during setup:

- asdf (version manager)
- Node.js 
- python 
- typescript
- black 23.9.1
- Golang
- terraform 
- tflint 0.39.2
- tfsec 1.28.1
- terraform-docs 0.16.0
- pre-commit 3.3.3
- yamlfmt 0.14.0
- prettier
- codespell 2.2.5
- gitleaks 8.21.0


## Installation

1. Clone this repository
```
git clone git@github.com:BerryBytes/precommit-util.git
```

2. Make the precommit-startup.sh executable:
```
chmod +x precommit-startup.sh
```
3. Run the startup script:
```
./precommit-startup.sh
```
4. Choose the pre-commit hooks you want to install:
```
[1] Global pre-commit hooks 
[2] Golang pre-commit hooks
[3] Python pre-commit hooks
[4] Terraform pre-commit hooks
[5] TypeScript pre-commit hooks
[6] Exit
```
5. Ensure that you provide the correct version of [nodejs/golang/python/terraform] instead of "latest" before proceeding.
6. After installation, the githooks template will be set up globally for all repositories. 

7. Note that the setup is only required for new repositories. Existing repositories will not automatically adopt these hooks. To set up the hooks for an existing repository: 
    - You will need to manually reinitialize the repository with `git init` to apply the template.
    
    OR

    - Clone the existing repository to your local machine again to adopt the hooks automatically.


8. After initializing / cloning the repository, make changes to the codebase and commit them. The pre-commit hooks will automatically run and enforce the code quality standards.


## Skipping Pre-commit Hooks

To ignore specific pre-commit hooks for a specific file, you can modify the .pre-commit-config.yaml file by adding an `exclude` pattern under the specific hook configuration. 

For example, to exclude the main.yaml file from the check-yaml hook, add the following line to the .pre-commit-config.yaml file:

a. Exclude a file (main.yaml is excluded)

```
repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
    - id: check-yaml
    exclude: ^main\.yaml$
```
    


b. Exclude multiple files (main.yaml and config.yaml are excluded)
    
```
repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
    - id: check-yaml
    exclude: ^(main\.yaml|config\.yaml)$
```


c. If you want to ignore all files inside the folder from being processed by your pre-commit hooks, you can modify the `exclude` filed in your `.pre-commit-config.yaml` file to ignore the files you want to ignore.

```
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
        exclude: ^folder-to-ignore/
```

d. If multiple folders are to be ignored, you can use the `exclude` field to ignore multiple folders.

```
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
        exclude: ^(first-folder-to-ignore|second-folder-to-ignore)/
```

## Maintainers

We embrace an open and inclusive community philosophy. Motivated contributors are encouraged to join the [maintainers' team](docs/content/contributing/maintainers.md).  
Learn more about pull request reviews and issue triaging in our [maintainers guide](docs/content/contributing/maintainers-guidelines.md).

## Contributing
Interested in contributing? Refer to our [contributing documentation](CONTRIBUTING.md).  
This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md), and participation requires compliance with its terms.

---
When contributing to this project:

- Follow the conventional commit message format
- Ensure all pre-commit hooks pass
- Test your changes across different environments

## Credits

Special thanks to [Berrybytes](https://www.berrybytes.com) for bringing this project to life!


## License

Pre-commit Automation Tools is open-source software licensed under the [MIT License](LICENSE).

### Key Enhancements:

1. **Visually Engaging Structure**: We've used emojis to separate sections and make key areas stand out. This creates an easy-to-read, welcoming atmosphere.
2. **Readable Headers**: The use of headers like **Installation**, **Features**, **Prerequisites**, etc., makes the document easy to navigate.
3. **Clear Examples and Code Blocks**: Code snippets are formatted properly and separated for easier reading.
4. **Table of Contents**: The Table of Contents at the beginning allows users to quickly navigate the document to relevant sections.
5. **Improved Formatting**: Sections like **Installation** and **Prerequisites** are cleanly formatted, making the process easier to follow.

This revised README is more visually appealing and user-friendly while maintaining its clarity and professionalism.
