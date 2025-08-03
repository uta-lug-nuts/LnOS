#!/bin/bash

# Debug: Log that we're starting
echo "LnOS autostart script starting at $(date)" >> /tmp/lnos-debug.log

# Prevent multiple instances
if [[ -f /tmp/lnos-autostart-running ]]; then
    echo "LnOS autostart already running, exiting..." >> /tmp/lnos-debug.log
    exit 0
fi

# Mark that we're running
touch /tmp/lnos-autostart-running
echo "Created running flag at $(date)" >> /tmp/lnos-debug.log

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
    
    # Use our hardcoded mirrorlist
    echo "Using hardcoded mirrorlist..."
    cat > /etc/pacman.d/mirrorlist << 'EOF'
# Arch Linux mirrorlist for LnOS ISO
# Using mirrors that support core and extra repositories

Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.leaseweb.net/archlinux/$repo/os/$arch
EOF
    
    pacman -Syy --noconfirm
fi

# Debug TTY information
echo "Current TTY: $(tty)" >> /tmp/lnos-debug.log
echo "Continuing with autostart..." >> /tmp/lnos-debug.log

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

# Check if the installer script exists
if [[ ! -f "/root/LnOS/scripts/LnOS-installer.sh" ]]; then
    echo "ERROR: LnOS installer not found at /root/LnOS/scripts/LnOS-installer.sh"
    echo "Available files in /root/LnOS/scripts/:"
    ls -la /root/LnOS/scripts/ 2>/dev/null || echo "Directory not found"
    echo ""
    echo "Dropping to shell..."
    rm -f /tmp/lnos-autostart-running
    exec /bin/bash
fi

# Check if installer is executable
if [[ ! -x "/root/LnOS/scripts/LnOS-installer.sh" ]]; then
    echo "ERROR: LnOS installer is not executable"
    echo "Making it executable..."
    chmod +x /root/LnOS/scripts/LnOS-installer.sh
fi

cd /root/LnOS/scripts

# Clean up the running flag
rm -f /tmp/lnos-autostart-running

# Execute the installer with error handling
echo "Executing: ./LnOS-installer.sh --target=$TARGET"
echo "Current directory: $(pwd)"
echo "Installer exists: $([[ -f "./LnOS-installer.sh" ]] && echo 'yes' || echo 'no')"
echo "Installer executable: $([[ -x "./LnOS-installer.sh" ]] && echo 'yes' || echo 'no')"

# Try to run the installer, but if it fails, drop to shell
if ! ./LnOS-installer.sh --target=$TARGET; then
    echo ""
    echo "ERROR: LnOS installer failed to start or crashed"
    echo "Dropping to shell for manual debugging..."
    echo ""
    exec /bin/bash
fi