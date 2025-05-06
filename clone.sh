#!/bin/bash

# GitHub organization URL
ORG_URL="https://github.com/remla25-team15"

# List of repositories to clone
REPOS=("app-frontend" "app-service" "model-service")

# Clone each repository
for REPO in "${REPOS[@]}"; do
    echo "Cloning $REPO..."
    git clone "${ORG_URL}/${REPO}.git"
done

echo "All repositories cloned successfully."
