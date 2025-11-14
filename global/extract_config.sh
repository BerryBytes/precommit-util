# #!/bin/bash

# # Extract the YAML config from setup_pre_commit_config function in global/pre-commit.sh
# # and save it to global/precommitFile/.pre-commit-config.yaml

# mkdir -p global/precommitFile

# sed -n '/cat > "\$file" <<'\''EOF'\''/,/EOF/p' global/pre-commit.sh | sed '1d;$d' > global/precommitFile/.pre-commit-config.yaml

# echo "Config extracted to global/precommitFile/.pre-commit-config.yaml"