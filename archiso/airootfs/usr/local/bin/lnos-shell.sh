#!/bin/bash

# LnOS Shell - runs installer once then drops to bash

# Check if we've already run the installer (use a more permanent location)
if [[ -f /root/.lnos-installer-completed ]]; then
    # Already ran, just drop to bash
    exec /bin/bash
fi

echo "=========================================="
echo "      Welcome to LnOS Live Environment"
echo "=========================================="
echo ""

# Wait a moment for system to settle
sleep 2

# Check if installer exists and run it
if [[ -f /root/LnOS/scripts/LnOS-installer.sh ]]; then
    cd /root/LnOS/scripts
    chmod +x ./LnOS-installer.sh
    echo "Starting LnOS installer..."
    ./LnOS-installer.sh --target=x86_64
    
    # Mark that installer has completed (in root's home directory)
    touch /root/.lnos-installer-completed
else
    echo "ERROR: LnOS installer not found!"
    echo "Available files in /root/LnOS/scripts/:"
    ls -la /root/LnOS/scripts/ 2>/dev/null || echo "Directory not found"
    
    # Mark as completed even if installer not found to prevent infinite loop
    touch /root/.lnos-installer-completed
fi

echo ""
echo "LnOS installer completed. Dropping to shell..."
echo ""

# Drop to bash shell
exec /bin/bash 