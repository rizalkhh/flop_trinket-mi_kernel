#!/usr/bin/env bash
#
# Dependency installation for ckbuild.
# Sourced by build/ckbuild.sh — runs on source.

install_deps_deb() {
    # Dependencies
    UB_DEPLIST="lz4 brotli flex bc cpio kmod ccache zip libtinfo5 python3"
    if grep -q "Ubuntu" /etc/os-release; then
        sudo apt update -qq
        sudo apt install $UB_DEPLIST -y
    else
        echo "INFO: Your distro is not Ubuntu, skipping dependencies installation..."
        echo "INFO: Make sure you have these dependencies installed before proceeding: $UB_DEPLIST"
    fi
}

## Pre-build dependencies
install_deps_deb