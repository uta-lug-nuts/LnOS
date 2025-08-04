#!/bin/bash

# Simple LnOS Autostart Script
# This runs directly and shows output on terminal

echo "=========================================="
echo "      Welcome to LnOS Live Environment"
echo "=========================================="
echo ""

# Wait a moment for system to settle
sleep 2

# Auto-detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    TARGET="x86_64"
elif [[ "$ARCH" == "aarch64" ]]; then
    TARGET="aarch64"
else
    TARGET="x86_64"  # fallback
fi

echo "Detected architecture: $ARCH (target: $TARGET)"
echo ""

# Check if installer exists
if [[ ! -f "/root/LnOS/scripts/LnOS-installer.sh" ]]; then
    echo "ERROR: LnOS installer not found!"
    echo "Available files in /root/LnOS/scripts/:"
    ls -la /root/LnOS/scripts/ 2>/dev/null || echo "Directory not found"
    echo ""
    echo "Dropping to shell..."
    exec /bin/bash
fi

# Make sure installer is executable
chmod +x /root/LnOS/scripts/LnOS-installer.sh

echo "Starting LnOS installer..."
echo ""

# Change to installer directory and run
cd /root/LnOS/scripts
exec ./LnOS-installer.sh --target=$TARGET