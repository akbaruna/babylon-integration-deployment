#!/bin/bash
set -euo pipefail

OP_DIR=$1
echo "OP_DIR: $OP_DIR"
echo

echo "Installing dependencies for OP L2..."
VERSIONS_FILE="$OP_DIR"/versions.json
if [ -f "$VERSIONS_FILE" ]; then
    # Read foundry and just version from versions.json
    FOUNDRY_VERSION=$(jq -r .foundry < "$VERSIONS_FILE")
    JUST_VERSION=$(jq -r .just < "$VERSIONS_FILE")
    GO_VERSION=$(jq -r .go < "$VERSIONS_FILE")
else
    echo "versions.json file $VERSIONS_FILE not found"
    exit 1
fi
echo

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install just if not already installed
if ! command_exists just || [[ "$(just --version 2>/dev/null | awk '{print $2}' || echo "")" != "${JUST_VERSION}" ]]; then
    echo "Installing just..."
    mkdir -p $HOME/.just
    curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to $HOME/.just --tag "${JUST_VERSION}"
    export PATH=$PATH:$HOME/.just
else
    echo "just is already installed."
fi
just --version
echo

# Check if Go is already installed
if ! command_exists go || [[ "$(go version 2>/dev/null | awk '{print $3}' | sed 's/^go//' || echo "")" != "${GO_VERSION}" ]]; then
    # Install Golang
    echo "Installing Go..."
    rm -rf /usr/local/go
    wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O - | tar -C /usr/local -xz
else
    echo "Go is already installed."
fi
go version
echo

# Install Foundry if not already installed
if ! command_exists forge || [[ "$(forge --version 2>/dev/null | sed -n 's/.*(\([a-f0-9]\{7\}\).*/\1/p' || echo "")" != "${FOUNDRY_VERSION:0:7}" ]]; then
    echo "Installing Foundry..."
    mkdir -p $HOME/.foundry/bin
    if [[ "$(uname)" == "Linux" ]]; then
        curl -L https://github.com/foundry-rs/foundry/releases/download/nightly-$FOUNDRY_VERSION/foundry_nightly_linux_amd64.tar.gz | tar xvzf - -C $HOME/.foundry/bin
    elif [[ "$(uname)" == "Darwin" ]]; then # for MacOS
        curl -L https://github.com/foundry-rs/foundry/releases/download/nightly-$FOUNDRY_VERSION/foundry_nightly_darwin_amd64.tar.gz | tar xvzf - -C $HOME/.foundry/bin
    else
        echo "unsupported $(uname) system"
        exit 1
    fi
    export PATH=$HOME/.foundry/bin:$PATH
else
    echo "Foundry is already installed"
fi
forge --version
echo