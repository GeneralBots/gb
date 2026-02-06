#!/bin/bash
#
# DEPENDENCIES-DEV.sh - Development Dependencies for General Bots
# 
# This script installs additional packages needed for BUILDING botserver from source.
# Only install these if you plan to compile the code yourself.
#
# Usage: sudo ./DEPENDENCIES-DEV.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  General Bots Development Dependencies${NC}"
echo -e "${GREEN}========================================${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Run as root (use sudo)${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Error: Cannot detect OS${NC}"
    exit 1
fi

echo -e "${YELLOW}OS: $OS${NC}"

install_debian_ubuntu() {
    apt-get update
    apt-get install -y \
        build-essential \
        gcc \
        g++ \
        clang \
        llvm-dev \
        libclang-dev \
        cmake \
        make \
        git \
        pkg-config \
        libssl-dev \
        libpq-dev \
        liblzma-dev \
        zlib1g-dev \
        libabseil-dev \
        protobuf-compiler \
        libprotobuf-dev \
        automake \
        bison \
        flex \
        gperf \
        libtool \
        m4 \
        nasm \
        python3 \
        python3-pip \
        nodejs \
        npm \
        libglib2.0-dev \
        libgobject-2.0-dev \
        libgio-2.0-dev \
        libgtk-3-dev \
        libwebkit2gtk-4.0-dev \
        libayatana-appindicator3-dev \
        librsvg2-dev

    # Cross-compilation toolchains
    apt-get install -y \
        gcc-aarch64-linux-gnu \
        gcc-arm-linux-gnueabihf \
        gcc-x86-64-linux-gnu || true
}

install_fedora_rhel() {
    dnf groupinstall -y "Development Tools"
    dnf install -y \
        gcc \
        gcc-c++ \
        clang \
        llvm-devel \
        clang-devel \
        cmake \
        make \
        git \
        pkgconf-devel \
        openssl-devel \
        libpq-devel \
        xz-devel \
        zlib-devel \
        abseil-cpp-devel \
        protobuf-compiler \
        protobuf-devel \
        automake \
        bison \
        flex \
        gperf \
        libtool \
        m4 \
        nasm \
        python3 \
        python3-pip \
        nodejs \
        npm \
        glib2-devel \
        gobject-introspection-devel \
        gtk3-devel \
        webkit2gtk3-devel \
        libappindicator-gtk3-devel \
        librsvg2-devel
}

install_arch() {
    pacman -Sy --noconfirm \
        base-devel \
        gcc \
        clang \
        llvm \
        cmake \
        make \
        git \
        pkgconf \
        openssl \
        postgresql-libs \
        xz \
        zlib \
        abseil-cpp \
        protobuf \
        automake \
        bison \
        flex \
        gperf \
        libtool \
        m4 \
        nasm \
        python \
        python-pip \
        nodejs \
        npm \
        glib2 \
        gobject-introspection \
        gtk3 \
        webkit2gtk \
        libappindicator-gtk3 \
        librsvg
}

install_alpine() {
    apk add --no-cache \
        build-base \
        gcc \
        g++ \
        clang \
        llvm-dev \
        clang-dev \
        cmake \
        make \
        git \
        pkgconf-dev \
        openssl-dev \
        postgresql-dev \
        xz-dev \
        zlib-dev \
        abseil-cpp-dev \
        protobuf-dev \
        protoc \
        automake \
        bison \
        flex \
        gperf \
        libtool \
        m4 \
        nasm \
        python3 \
        py3-pip \
        nodejs \
        npm \
        glib-dev \
        gobject-introspection-dev \
        gtk+3.0-dev \
        webkit2gtk-dev \
        libappindicator-dev \
        librsvg-dev
}

case $OS in
    ubuntu|debian|linuxmint|pop)
        install_debian_ubuntu
        ;;
    fedora|rhel|centos|rocky|almalinux)
        install_fedora_rhel
        ;;
    arch|manjaro)
        install_arch
        ;;
    alpine)
        install_alpine
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        echo "Required development packages:"
        echo "  - build-essential/base-devel"
        echo "  - gcc, g++, clang"
        echo "  - cmake, make, git"
        echo "  - Development headers for:"
        echo "    - OpenSSL, PostgreSQL, XZ, zlib"
        echo "    - Abseil, Protobuf, LLVM"
        exit 1
        ;;
esac

echo -e "${GREEN}Development dependencies installed!${NC}"
echo ""
echo "Install Rust if not already installed:"
echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
echo ""
echo "Build options:"
echo "  Full workspace (includes desktop apps):"
echo "    cargo build --release"
echo ""
echo "  Server only (faster, no GTK needed):"
echo "    cargo build --release -p botserver -p botlib -p bottest"
