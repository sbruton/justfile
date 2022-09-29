# Install GitHub CLI using apt
@install-gh:
    apt-get update && apt-get install gh -y

# Install packer using apt
@install-packer:
    apt-get update && apt-get install packer -y
        

# Install Rust via rustup using direct download
@install-rust:
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -c '-y'

# Install terraform using homebrew apt
@install-terraform:
    apt-get update && apt-get install terraform -y