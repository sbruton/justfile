# minimum rustc version supported
_rust_min := "1.64.0"

# Backup an S3 bucket
backup-s3 ts dir bucket handle:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    mkdir -p backup/{{handle}}.{{ts}}
    aws s3 sync s3://{{bucket}}/ backup/{{handle}}.{{ts}}/

# Build for local target
build ts dir *FLAGS:
    #!/usr/bin/env bash
    set -euxo pipefail
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    cd {{dir}}
    cargo build {{FLAGS}}

# Build for all supported targets
@build-all ts dir:
    just build-apple-arm {{ts}} {{dir}}
    just build-apple-x86 {{ts}} {{dir}}
    just build-linux-x86-gnu {{ts}} {{dir}}
    just build-linux-arm-gnu {{ts}} {{dir}}
    just build-windows-x86-gnu {{ts}} {{dir}}

# Build for Apple macOS targeting the 64-bit Apple ISA (e.g., Apple Silicon Macs)
build-apple-arm ts dir *FLAGS:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}} 
    just -f {{absolute_path("justfile")}} _build-target {{ts}} {{dir}} aarch64-apple-darwin {{FLAGS}}

# Build for Apple macOS targeting the 64-bit x86 (amd64) ISA (e.g., Legacy Intel Macs)
build-apple-x86 ts dir *FLAGS:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    just -f {{absolute_path("justfile")}} _build-target {{ts}} {{dir}} x86_64-apple-darwin {{FLAGS}}

# Build for GNU/Linux targeting the 64-bit ARMv8 (AArch64) ISA (e.g., AWS Graviton)
build-linux-arm-gnu ts dir *FLAGS:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}} 
    rustup target add aarch64-unknown-linux-gnu
    brew tap messense/macos-cross-toolchains
    brew install aarch64-unknown-linux-gnu
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-unknown-linux-gnu-gcc \
    AR_aarch64_unknown_linux_gnu=aarch64-unknown-linux-gnu-ar \
    CC_aarch64_unknown_linux_gnu=aarch64-unknown-linux-gnu-gcc \
    CXX_aarch64_unknown_linux_gnu=aarch64-unknown-linux-gnu-g++ \
    RUSTFLAGS="-C link-arg=-Wl,--build-id" \
    just -f {{absolute_path("justfile")}} _build-target {{ts}} {{dir}} aarch64-unknown-linux-gnu {{FLAGS}}

# Build for GNU/Linux targeting the 64-bit ARMv7 ISA (e.g., Raspberry Pi 3B/4B)
build-linux-armv7-gnu ts dir *FLAGS:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    rustup target add armv7-unknown-linux-gnueabihf
    brew tap messense/macos-cross-toolchains
    brew install armv7-unknown-linux-gnueabihf
    CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=armv7-unknown-linux-gnueabihf-gcc \
    AR_armv7_unknown_linux_gnueabihf=armv7-unknown-linux-gnueabihf-ar \
    CC_armv7_unknown_linux_gnueabihf=armv7-unknown-linux-gnueabihf-gcc \
    CXX_armv7_unknown_linux_gnueabihf=armv7-unknown-linux-gnueabihf-g++ \
    RUSTFLAGS="-C link-arg=-Wl,--build-id" \
    just -f {{absolute_path("justfile")}} _build-target {{ts}} {{dir}} armv7-unknown-linux-gnueabihf {{FLAGS}}

# Build for GNU/Linux targeting the 32-bit ARMv6 ISA (e.g., Raspberry Pi Zero / Zero W)
build-linux-armv6-gnu ts dir *FLAGS:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    rustup target add arm-unknown-linux-gnueabihf
    brew tap messense/macos-cross-toolchains
    brew install arm-unknown-linux-gnueabihf
    CARGO_TARGET_ARM_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-unknown-linux-gnueabihf-gcc \
    AR_arm_unknown_linux_gnueabihf=arm-unknown-linux-gnueabihf-ar \
    CC_arm_unknown_linux_gnueabihf=arm-unknown-linux-gnueabihf-gcc \
    CXX_arm_unknown_linux_gnueabihf=arm-unknown-linux-gnueabihf-g++ \
    RUSTFLAGS="-C link-arg=-Wl,--build-id" \
    just -f {{absolute_path("justfile")}} _build-target {{ts}} {{dir}} arm-unknown-linux-gnueabihf {{FLAGS}}

# Build for GNU/Linux targeting the 64-bit x86 (amd64) ISA (e.g., Intel/AMD PCs)
build-linux-x86-gnu ts dir *FLAGS:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-unknown-linux-gnu-gcc \
    AR_x86_64_unknown_linux_gnu=x86_64-unknown-linux-gnu-ar \
    CC_x86_64_unknown_linux_gnu=x86_64-unknown-linux-gnu-gcc \
    CXX_x86_64_unknown_linux_gnu=x86_64-unknown-linux-gnu-g++ \
    RUSTFLAGS="-C link-arg=-Wl,--build-id" \
    just -f {{absolute_path("justfile")}} _build-target {{ts}} {{dir}} x86_64-unknown-linux-gnu {{FLAGS}}

# Build for VMs providing a WASM32 ISA (e.g., web browsers)
build-wasm32 ts dir *FLAGS:
    #!/usr/bin/env bash
    set -euxo pipefail
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    cd {{dir}}
    trunk build --release {{FLAGS}}

# Build for GNU/Windows targeting the 64-bit x86 (amd64) ISA (e.g, Intel/AMD PCs)
build-windows-x86-gnu ts dir *FLAGS:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc \
    AR_x86_64_pc_windows_gnu=x86_64-w64-mingw32-ar \
    CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc \
    CXX_x86_64_pc_windows_gnu=x86_64-w64-mingw32-g++ \
    RUSTFLAGS="-C link-arg=-Wl,--build-id" \
    just -f {{absolute_path("justfile")}} _build-target {{ts}} {{dir}} x86_64-pc-windows-gnu {{FLAGS}}

# Run all lints and tests
check ts dir:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    @for rust_version in $(semver seq --minor --minor-max 100 {{_rust_min}} `rustc --version | awk '{print $2}'`); do \
        just -f {{absolute_path("log.justfile")}} info "Checking rustc v${rust_version}"; \
        cargo +$rust_version check; \
    done

# Install Homebrew if missing (macos only)
@check-brew ts dir:
    just -f {{absolute_path("log.justfile")}} info "Checking for homebrew"
    type brew 2>&1 > /dev/null || just install-brew {{ts}} {{dir}}
    if [[ "{{os()}}" == "macos" ]]; then type gdate 2>&1 > /dev/null || brew install coreutils; fi

# Install GitHub CLI if missing
@check-gh ts dir:
    just -f {{absolute_path("log.justfile")}} info "Checking for github cli" 
    type gh 2>&1 > /dev/null || just install-gh {{ts}} {{dir}}

# Install packer if missing
@check-packer ts dir:
    just -f {{absolute_path("log.justfile")}} info "Checking for packer"
    type packer 2>&1 > /dev/null || just install-packer {{ts}} {{dir}}

# Install Rust if missing
@check-rust ts dir:
    just -f {{absolute_path("log.justfile")}} info "Checking for rust"
    type rustc 2>&1 > /dev/null || just install-rust {{ts}} {{dir}}
    type cargo-next 2>&1 > /dev/null || cargo install --locked cargo-next
    semver cmp `rustc --version | awk '{print $2}'` lt 1.64.0 2>&1 > /dev/null && just update-rust || true 2>&1 > /dev/null

# Install semver if missing
@check-semver ts dir:
    just -f {{absolute_path("log.justfile")}} info "Checking for semver"
    type semver 2>&1 > /dev/null || just install-semver {{ts}} {{dir}}

# Install terraform if missing
@check-terraform ts dir:
    just -f {{absolute_path("log.justfile")}} info "Checking for terraform"
    type terraform 2>&1 > /dev/null || just install-terraform {{ts}} {{dir}}

# Install trunk if missing
@check-trunk ts dir:
    just -f {{absolute_path("log.justfile")}} info "Checking for trunk"
    type trunk 2>&1 > /dev/null || just install-trunk {{ts}} {{dir}}

# Check entire toolchain and install all missing components
@check-toolchain ts dir:
    just -f {{absolute_path("justfile")}} check-brew {{ts}} {{dir}}
    just -f {{absolute_path("justfile")}} check-gh {{ts}} {{dir}}
    just -f {{absolute_path("justfile")}} check-rust {{ts}} {{dir}}
    just -f {{absolute_path("justfile")}} check-packer {{ts}} {{dir}}
    just -f {{absolute_path("justfile")}} check-terraform {{ts}} {{dir}}
    just -f {{absolute_path("justfile")}} check-semver {{ts}} {{dir}}
    just -f {{absolute_path("justfile")}} check-trunk {{ts}} {{dir}}

# Remove all build artifacts
clean ts dir:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    cargo clean
    if [[ -d dist ]]; then rm -rf dist; fi

# Deploy a web app to AWS S3 and CloudFront
deploy-web ts dir subdir bucket distribution:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}/{{subdir}}
    trunk build --release
    just -f {{absolute_path("justfile")}} snapshot-s3 {{ts}} {{dir}} {{bucket}} {{bucket}}-snapshot 
    aws s3 sync dist/ s3://{{bucket}}/
    just -f {{absolute_path("justfile")}} web-cache-invalidate {{ts}} {{dir}} {{distribution}}

# Update infrastructure using terraform
infra ts dir subdir *FLAGS:
    just -f {{absolute_path("justfile")}} check-terraform {{ts}} {{dir}}
    cd {{dir}}/{{subdir}} && terraform init
    cd {{dir}}/{{subdir}} && terraform apply {{FLAGS}}

# Install homebrew using direct download (macos only)
install-brew ts dir:
    just -f {{absolute_path("log.justfile")}} info "Installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install GitHub CLI using homebrew (macos) or apt (linux)
@install-gh ts dir:
    just -f {{absolute_path("log.justfile")}} info "Installing github cli"
    just -f {{os()}}.justfile install-gh

# Install packer using homebrew (macos) or apt (linux)
@install-packer ts dir:
    just -f {{absolute_path("log.justfile")}} info "Installing packer"
    just -f {{os()}}.justfile install-packer

# Install Rust via rustup using homebrew (macos) or direct download (linux)
@install-rust ts dir:
    just -f {{absolute_path("log.justfile")}} info "Installing rust"
    just -f {{os()}}.justfile install-rust

# Install semver cli utility using cargo
install-semver ts dir:
    just -f {{absolute_path("log.justfile")}} info "Installing semver"
    cargo install semver-util

# Install terraform using homebrew (macos) or apt (linux)
@install-terraform ts dir:
    just -f {{absolute_path("log.justfile")}} info "Installing terraform"
    just -f {{os()}}.justfile install-terraform

# Install trunk using cargo
@install-trunk ts dir:
    just -f {{absolute_path("log.justfile")}} info "Installing trunk"
    cargo install trunk

# Package deb for GNU/Linux targeting the 32-bit ARMv6 ISA (e.g., Raspberry Pi Zero / Zero W)
package-linux-armv6-gnu-deb ts dir *FLAGS:
    just -f {{absolute_path("justfile")}} check-toolchain {{ts}} {{dir}}
    rustup target add arm-unknown-linux-gnueabihf
    brew tap messense/macos-cross-toolchains
    brew install arm-unknown-linux-gnueabihf
    CARGO_TARGET_ARM_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-unknown-linux-gnueabihf-gcc \
    AR_arm_unknown_linux_gnueabihf=arm-unknown-linux-gnueabihf-ar \
    CC_arm_unknown_linux_gnueabihf=arm-unknown-linux-gnueabihf-gcc \
    CXX_arm_unknown_linux_gnueabihf=arm-unknown-linux-gnueabihf-g++ \
    RUSTFLAGS="-C link-arg=-Wl,--build-id" \
    cd {{dir}} && cargo deb -v --target arm-unknown-linux-gnueabihf {{FLAGS}}

# Publish Amazon Machine Image to all US regions
publish-ami-us ts dir subdir artifact tag:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}/{{subdir}}
    artifact="{{artifact}}"
    packer init .
    packer fmt .
    packer validate \
        --var ami_version={{tag}} \
        --var ami_build_tag=`aarch64-unknown-linux-gnu-readelf -n ../target/aarch64-unknown-linux-gnu/release/$artifact | perl -0pe 's/.+\.note\.gnu\.build-id//smg' | perl -0pe 's/.+Build ID: //smg'` \
        .
    packer build \
        --var ami_version={{tag}} \
        --var ami_build_tag=`aarch64-unknown-linux-gnu-readelf -n ../target/aarch64-unknown-linux-gnu/release/$artifact | perl -0pe 's/.+\.note\.gnu\.build-id//smg' | perl -0pe 's/.+Build ID: //smg'` \
        .

# Publish binaries to GitHub release associated with current tag
publish-bins ts dir:
    #!/usr/bin/env bash
    set -euxo pipefail
    just build-all {{ts}} {{dir}}
    cd {{dir}}
    tag=`git describe --tag`
    if [[ -d dist ]]; then rm -rf dist; fi
    mkdir dist
    for i in {0..99}
    do
        cargo-config config bin.$i.name 2>&1 > /dev/null && just -f {{absolute_path("justfile")}} _stage {{ts}} {{dir}} $tag $i || break
    done
    cd dist
    set +e
    for asset in *
    do
        gh release delete-asset -y $tag $asset
    done
    set -e
    cd - 2>&1 > /dev/null
    gh release upload $tag dist/*

# Create a timestamped snapshot of an s3 bucket in a different bucket
snapshot-s3 ts dir from_bucket to_bucket:
    #!/usr/bin/env bash
    set -euxo pipefail
    just -f {{absolute_path("justfile")}} backup-s3 {{ts}} {{dir}} {{from_bucket}} {{from_bucket}}
    cd {{dir}}
    aws s3 sync backup/{{from_bucket}}.{{ts}}/ s3://{{to_bucket}}/{{from_bucket}}.{{ts}}/

# Update rust toolchain for all supported versions
update-rust ts dir:
    rustup update
    @for rust_version in $(semver seq --minor --minor-max 100 {{_rust_min}} `rustc --version | awk '{print $2}'`); do \
        just -f {{absolute_path("log.justfile")}} info "Updating rustc v${rust_version}"; \
        cargo +$rust_version version 2>&1 > /dev/null || rustup toolchain install $rust_version; \
    done

# Invalidate AWS CloudFront cache
web-cache-invalidate ts dir distribution *FLAGS:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    aws cloudfront create-invalidation --distribution-id {{distribution}} --paths '/*'

_build-target ts dir target *FLAGS:
    #!/usr/bin/env bash
    set -euxo pipefail
    just -f {{absolute_path("log.justfile")}} info "Building for {{target}}"
    cd {{dir}}
    just -f {{absolute_path("justfile")}} build {{ts}} {{dir}} --release --target {{target}} {{FLAGS}}

_stage-artifact ts dir tag arch bin:
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

_stage-bin ts dir tag index arch:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} _stage-artifact {{ts}} {{dir}} {{tag}} {{arch}} `cargo-config config bin.{{index}}.name | sed -e 's/"//g'`
    
_stage-win ts dir tag index arch:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} _stage-artifact {{ts}} {{dir}} {{tag}} {{arch}} `cargo-config config bin.{{index}}.name | sed -e 's/"//g'`

@_stage ts dir tag index:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{dir}}
    just -f {{absolute_path("justfile")}} _stage-bin {{ts}} {{dir}} {{tag}} {{index}} aarch64-apple-darwin
    just -f {{absolute_path("justfile")}} _stage-bin {{ts}} {{dir}} {{tag}} {{index}} aarch64-unknown-linux-gnu
    just -f {{absolute_path("justfile")}} _stage-bin {{ts}} {{dir}} {{tag}} {{index}} x86_64-apple-darwin
    just -f {{absolute_path("justfile")}} _stage-bin {{ts}} {{dir}} {{tag}} {{index}} x86_64-unknown-linux-gnu
    just -f {{absolute_path("justfile")}} _stage-win {{ts}} {{dir}} {{tag}} {{index}} x86_64-pc-windows-gnu
