#!/bin/bash

# Prevent multiple instances
if [[ -f /tmp/lnos-autostart-running ]]; then
    echo "LnOS autostart already running, exiting..."
    exit 0
fi

# Mark that we're running
touch /tmp/lnos-autostart-running

# Wait for system to fully boot and network to be ready
echo "Waiting for system to be ready..."
sleep 5

# Wait for network connectivity
echo "Checking network connectivity..."
for i in {1..30}; do
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo "Network is ready!"
        break
    fi
    echo "Waiting for network... ($i/30)"
    sleep 2
done

# Test pacman repositories
echo "Testing pacman repositories..."
if ! pacman -Sy --noconfirm >/dev/null 2>&1; then
    echo "WARNING: Pacman repository test failed, trying to fix..."
    pacman-key --init
    pacman-key --populate archlinux
    
    # Try to update mirrorlist with more reliable mirrors
    echo "Updating mirrorlist with reliable mirrors..."
    cat > /etc/pacman.d/mirrorlist << 'EOF'
# Arch Linux mirrorlist for LnOS ISO
# Generated with reliable mirrors that support all repositories

## Global mirrors
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.umd.edu/archlinux/$repo/os/$arch
Server = https://mirror.csclub.uwaterloo.ca/archlinux/$repo/os/$arch
Server = https://mirror.rise.ph/archlinux/$repo/os/$arch

## US mirrors
Server = https://mirror.lty.me/archlinux/$repo/os/$arch
Server = https://mirror.xtom.com.hk/archlinux/$repo/os/$arch
Server = https://mirror.selfnet.de/archlinux/$repo/os/$arch

## Fallback to official
Server = https://archlinux.mirror.constant.com/$repo/os/$arch
EOF
    
    pacman -Syy --noconfirm
fi

# Skip if not on tty1
if [[ $(tty) != "/dev/tty1" ]]; then
    rm -f /tmp/lnos-autostart-running
    exit 0
fi

# Clear screen and show welcome
clear
echo "=========================================="
echo "      Welcome to LnOS Live Environment"
echo "=========================================="
echo ""
echo "Network should be automatically configured."
echo ""

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
echo "Starting LnOS installer automatically in 5 seconds..."
echo "Press Ctrl+C to cancel and drop to shell."
echo ""

# 5 second countdown
for i in {5..1}; do
    echo -n "$i... "
    sleep 1
done
echo ""
echo ""

echo "Starting LnOS installer..."
cd /root/LnOS/scripts

# Clean up the running flag
rm -f /tmp/lnos-autostart-running

# Execute the installer
exec ./LnOS-installer.sh --target=$TARGET