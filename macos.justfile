@check-brew:
    type brew 2>&1 > /dev/null || just _install-brew

# Install Homebrew using direct download
install-brew:
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install GitHub CLI using homebrew
install-gh:
    brew install gh

# Install packer using homebrew
install-packer:
    brew install packer

# Install Rust via rustup using homebrew
install-rust:
    brew install rustup-init
    rustup-init -y

# Install terraform using homebrew
@install-terraform:
    brew install terraform
