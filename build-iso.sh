#!/bin/bash

# Build script for LnOS custom Arch ISO
# Usage: ./build-iso.sh [x86_64|aarch64]

set -e

ARCH=${1:-x86_64}
PROFILE_DIR="$(pwd)/archiso"
OUTPUT_DIR="$(pwd)/out"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root (allow in container environment)
if [[ $EUID -eq 0 ]] && [[ ! -f /.dockerenv ]] && [[ ! -f /run/.containerenv ]]; then
    print_error "This script should not be run as root for security reasons."
    print_error "If you're in a container, this check should be bypassed automatically."
    exit 1
fi

# Check if archiso is installed
if ! command -v mkarchiso &> /dev/null; then
    print_error "archiso is not installed. Please install it with: sudo pacman -S archiso"
    exit 1
fi

# Validate architecture
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
    print_error "Unsupported architecture: $ARCH"
    print_error "Supported architectures: x86_64, aarch64"
    exit 1
fi

print_status "Building LnOS ISO for $ARCH architecture..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Update profiledef.sh for the target architecture
sed -i "s/^arch=.*/arch=\"$ARCH\"/" "$PROFILE_DIR/profiledef.sh"

# Copy the appropriate packages file for archiso (it expects packages.x86_64)
if [[ "$ARCH" == "aarch64" ]] && [[ -f "$PROFILE_DIR/packages.aarch64" ]]; then
    cp "$PROFILE_DIR/packages.aarch64" "$PROFILE_DIR/packages.x86_64"
    print_status "Using packages.aarch64 for aarch64 build"
elif [[ "$ARCH" == "x86_64" ]] && [[ -f "$PROFILE_DIR/packages.x86_64" ]]; then
    print_status "Using packages.x86_64 for x86_64 build"
else
    print_warning "packages.$ARCH not found, using existing packages.x86_64"
fi

# Ensure our custom mirrorlist is used during the build
print_status "Setting up custom mirrorlist for build..."
mkdir -p "$PROFILE_DIR/airootfs/etc/pacman.d"
if [[ -f "$PROFILE_DIR/airootfs/etc/pacman.d/mirrorlist" ]]; then
    print_status "Using custom mirrorlist from airootfs"
else
    print_warning "Custom mirrorlist not found, creating one..."
    cat > "$PROFILE_DIR/airootfs/etc/pacman.d/mirrorlist" << 'EOF'
# Arch Linux mirrorlist for LnOS ISO
# Using mirrors that support core and extra repositories

Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.leaseweb.net/archlinux/$repo/os/$arch
EOF
fi

# Build the ISO
print_status "Starting ISO build process..."
if [[ $EUID -eq 0 ]]; then
    mkarchiso -v -w /tmp/archiso-tmp -o "$OUTPUT_DIR" "$PROFILE_DIR"
else
    sudo mkarchiso -v -w /tmp/archiso-tmp -o "$OUTPUT_DIR" "$PROFILE_DIR"
fi

# Check if build was successful
if [[ $? -eq 0 ]]; then
    print_status "ISO build completed successfully!"
    print_status "Output directory: $OUTPUT_DIR"
    
    # Show detailed file information
    if ls "$OUTPUT_DIR"/*.iso 1> /dev/null 2>&1; then
        echo ""
        print_status "Built ISO files:"
        for iso in "$OUTPUT_DIR"/*.iso; do
            size_mb=$(du -m "$iso" | cut -f1)
            size_human=$(du -h "$iso" | cut -f1)
            print_status "$(basename "$iso"): ${size_human} (${size_mb} MB)"
        done
        echo ""
        
        # Warn if ISO is still too large
        for iso in "$OUTPUT_DIR"/*.iso; do
            size_mb=$(du -m "$iso" | cut -f1)
            if [[ $size_mb -gt 1000 ]]; then
                print_warning "ISO $(basename "$iso") is ${size_mb}MB - still quite large for a network installer"
                print_warning "Consider removing more packages from archiso/packages.x86_64"
            elif [[ $size_mb -gt 500 ]]; then
                print_warning "ISO $(basename "$iso") is ${size_mb}MB - consider removing more packages if possible"
            else
                print_status "ISO $(basename "$iso") size looks good for a network installer!"
            fi
        done
    else
        print_warning "No ISO files found in output directory"
    fi
else
    print_error "ISO build failed!"
    exit 1
fi

print_status "Build process completed for $ARCH architecture."
print_status "GRUB debug mode and boot fixes applied."
