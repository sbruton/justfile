# minimum rustc version supported
_rust_min := "1.60.0"

# Install GitHub CLI using homebrew (macos) or apt (linux)
@install_gh:
    just -f {{os()}}.justfile install_gh

# Install Rust via rustup, the latter installed using homebrew (macos) or direct download (linux)
@install_rust:
    just -f {{os()}}.justfile install_rust

# Install semver cli utility using cargo
install_semver:
    cargo install semver-util

# Update rust toolchain for all supported versions
update_rust:
    rustup update
    @for rust_version in $(semver seq --minor --minor-max 100 {{_rust_min}} `rustc --version | awk '{print $2}'`); do \
        just -f {{absolute_path("log.justfile")}} info "Updating rustc v${rust_version}"; \
        cargo +$rust_version version 2>&1 > /dev/null || rustup toolchain install $rust_version; \
    done

# Build for local target
build dir *FLAGS: check_toolchain
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    cargo build {{FLAGS}}

# Build for all supported targets
@build-all dir:
    just build-apple-arm {{dir}}
    just build-apple-x86 {{dir}}
    just build-linux-x86-gnu {{dir}}
    just build-linux-arm-gnu {{dir}}
    just build-windows-x86-gnu {{dir}}

# Build for Apple macOS targeting the 64-bit Apple ISA (e.g., Apple Silicon Macs)
build-apple-arm dir *FLAGS: check_toolchain 
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} build {{dir}} --release --target aarch64-apple-darwin {{FLAGS}}

# Build for Apple macOS targeting the 64-bit x86 (amd64) ISA (e.g., Legacy Intel Macs)
build-apple-x86 dir *FLAGS: check_toolchain 
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} build {{dir}} --release --target x86_64-apple-darwin {{FLAGS}}

# Build for GNU/Linux targeting the 64-bit ARMv8 (AArch64) ISA (e.g., AWS Graviton)
build-linux-arm-gnu dir *FLAGS: check_toolchain 
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} build {{dir}} --release --target aarch64-unknown-linux-gnu {{FLAGS}}

# Build for GNU/Linux targeting the 32-bit ARMv7 ISA (e.g., Raspberry Pi)
build-linux-armv7-gnu dir *FLAGS: check_toolchain 
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} build {{dir}} --release --target armv7-unknown-linux-gnueabihf {{FLAGS}}

# Build for GNU/Linux targeting the 64-bit x86 (amd64) ISA (e.g., Intel/AMD PCs)
build-linux-x86-gnu dir *FLAGS: check_toolchain 
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} build {{dir}} --release --target x86_64-unknown-linux-gnu {{FLAGS}}

# Build for GNU/Windows targeting the 64-bit x86 (amd64) ISA (e.g, Intel/AMD PCs)
build-windows-x86-gnu dir *FLAGS: check_toolchain 
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} build {{dir}} --release --target x86_64-pc-windows-gnu {{FLAGS}}

# Run all lints and tests
check: check_toolchain
    @for rust_version in $(semver seq --minor --minor-max 100 {{_rust_min}} `rustc --version | awk '{print $2}'`); do \
        just -f {{absolute_path("log.justfile")}} info "Checking rustc v${rust_version}"; \
        cargo +$rust_version check; \
    done

# Install GitHub CLI if missing
@check_gh:
    type gh 2>&1 > /dev/null || just install_gh

# Install Rust if missing
@check_rust:
    type rustc 2>&1 > /dev/null || just install_rust
    semver compare `rustc --version | awk '{print $2}'` lt 1.64.0 2>&1 > /dev/null && just update_rust

# Check entire toolchain and install all missing components
@check_toolchain: check_gh check_rust 

# Remove all build artifacts
clean dir:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    cargo clean
    if [[ -d dist ]]; then rm -rf dist; fi

# Publish binaries to GitHub release associated with current tag
publish-bins dir:
    #!/usr/bin/env bash
    set -euxo pipefail
    just build-all {{dir}}
    cd {{dir}}
    tag=`git describe --tag`
    if [[ -d dist ]]; then rm -rf dist; fi
    mkdir dist
    for i in {0..99}
    do
        cargo-config config bin.$i.name 2>&1 > /dev/null && just -f {{absolute_path("justfile")}} _stage {{dir}} $tag $i || break
    done
    cd dist
    set +e
    for asset in *
    do
        gh release delete-asset -y $tag $asset
    done
    set -e
    cd -
    gh release upload $tag dist/*

_stage_artifact dir tag arch bin:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    dist={{bin}}.{{tag}}.{{arch}}
    if [[ "`echo {{arch}} | awk -F- '{print $3}'`" == "windows" ]]
    then
        cp target/{{arch}}/release/{{bin}}.exe dist/$dist.exe
    else
        cp target/{{arch}}/release/{{bin}} dist/$dist
    fi

_stage_bin dir tag index arch:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} _stage_artifact {{dir}} {{tag}} {{arch}} `cargo-config config bin.{{index}}.name | sed -e 's/"//g'`
    
_stage_win dir tag index arch:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} _stage_artifact {{dir}} {{tag}} {{arch}} `cargo-config config bin.{{index}}.name | sed -e 's/"//g'`

@_stage dir tag index:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} _stage_bin {{dir}} {{tag}} {{index}} aarch64-apple-darwin
    just -f {{absolute_path("justfile")}} _stage_bin {{dir}} {{tag}} {{index}} aarch64-unknown-linux-gnu
    just -f {{absolute_path("justfile")}} _stage_bin {{dir}} {{tag}} {{index}} x86_64-apple-darwin
    just -f {{absolute_path("justfile")}} _stage_bin {{dir}} {{tag}} {{index}} x86_64-unknown-linux-gnu
    just -f {{absolute_path("justfile")}} _stage_win {{dir}} {{tag}} {{index}} x86_64-pc-windows-gnu
