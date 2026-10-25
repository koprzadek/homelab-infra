#!/bin/bash
set -e

if ! command -v sops &> /dev/null || ! command -v yq &> /dev/null; then
    echo "Error: sops and yq are required to run this script."
    exit 1
fi

SOPS_FILE="secrets.sops.yaml"
if [ ! -f "$SOPS_FILE" ]; then
    echo "Error: $SOPS_FILE not found."
    exit 1
fi

echo "Decrypting R2 credentials..."
export SOPS_AGE_KEY_FILE=~/.config/age/key.txt
export AWS_ACCESS_KEY_ID=$(sops -d "$SOPS_FILE" | yq -r '.cloudflare.key_id')
export AWS_SECRET_ACCESS_KEY=$(sops -d "$SOPS_FILE" | yq -r '.cloudflare.access_key')

echo "Running: tofu $@"
tofu "$@"

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
echo "Credentials cleared from memory."
