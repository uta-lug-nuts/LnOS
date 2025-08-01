#!/bin/bash

# LnOS Development Environment Setup Script
# This script sets up the development environment for building ISOs

set -e

echo "=== Setting up LnOS Development Environment ==="

# Ensure we're in the right directory
cd /workspace

# Verify archiso installation
if ! command -v mkarchiso &> /dev/null; then
    echo "❌ archiso not found! Installing..."
    pacman -S --noconfirm archiso
else
    echo "✅ archiso is installed"
fi

# Make build script executable
if [ -f "build-iso.sh" ]; then
    chmod +x build-iso.sh
    echo "✅ build-iso.sh is executable"
else
    echo "⚠️  build-iso.sh not found in workspace"
fi

# Make customize script executable
if [ -f "archiso/airootfs/root/customize_airootfs.sh" ]; then
    chmod +x archiso/airootfs/root/customize_airootfs.sh
    echo "✅ customize_airootfs.sh is executable"
else
    echo "⚠️  customize_airootfs.sh not found"
fi

# Verify archiso profile structure
echo "📁 Checking archiso profile structure..."
required_files=(
    "archiso/profiledef.sh"
    "archiso/pacman.conf"
    "archiso/packages.x86_64"
    "archiso/packages.aarch64"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

# Check for installer script
if [ -f "scripts/LnOS-installer.sh" ]; then
    echo "✅ LnOS installer script found"
    chmod +x scripts/LnOS-installer.sh
else
    echo "❌ LnOS installer script missing"
fi

# Create output directory
mkdir -p out
echo "✅ Output directory created"

# Test basic archiso functionality
echo "🔧 Testing archiso..."
if mkarchiso --help &> /dev/null; then
    echo "✅ archiso is working correctly"
else
    echo "❌ archiso test failed"
    exit 1
fi

echo ""
echo "=== Development Environment Ready! ==="
echo ""
echo "Quick Start:"
echo "  ./build-iso.sh x86_64     # Build x86_64 ISO"
echo "  ./build-iso.sh aarch64    # Build aarch64 ISO"
echo "  clean-build               # Clean build artifacts"
echo ""
echo "The built ISOs will be available in the './out/' directory"
echo ""