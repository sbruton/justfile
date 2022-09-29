# Install GitHub CLI using apt
@install_gh:
    apt-get update && apt-get install gh -y

# Install packer using apt
@install_packer:
    apt-get update && apt-get install packer -y
        

# Install Rust via rustup using direct download
@install_rust:
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -c '-y'

# Install terraform using homebrew apt
@install_terraform:
    apt-get update && apt-get install terraform -y