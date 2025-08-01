#!/bin/bash

# GitHub organization URL
ORG_URL="https://github.com/remla25-team15"

# List of repositories to clone
REPOS=("app-frontend" "app-service" "model-service" "lib-ml" "model-training" "lib-version")

# Clone each repository
for REPO in "${REPOS[@]}"; do
    echo "Cloning $REPO..."
    git clone "${ORG_URL}/${REPO}.git" "../${REPO}"
done

echo "All repositories cloned successfully."
