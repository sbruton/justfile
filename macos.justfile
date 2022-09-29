@check_brew:
    type brew 2>&1 > /dev/null || just _install_brew

install_brew:
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

install_gh:
    brew install gh

install_rust:
    brew install rustup-init
    rustup-init -y

