@check_brew:
    type brew 2>&1 > /dev/null || just _install_brew

# Install Homebrew using direct download
install_brew:
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install GitHub CLI using homebrew
install_gh:
    brew install gh

# Install packer using homebrew
install_packer:
    brew install packer

# Install Rust via rustup using homebrew
install_rust:
    brew install rustup-init
    rustup-init -y

# Install terraform using homebrew
@install_terraform:
    brew install terraform
