#!/bin/bash

# LnOS Shell - runs installer once then removes itself

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
    
    # Remove autostart immediately when installer starts
    rm -f /usr/local/bin/lnos-shell.sh
    chsh -s /bin/bash root
    
    # Run the installer
    ./LnOS-installer.sh --target=x86_64
else
    echo "ERROR: LnOS installer not found!"
    echo "Available files in /root/LnOS/scripts/:"
    ls -la /root/LnOS/scripts/ 2>/dev/null || echo "Directory not found"
    
    # Remove autostart even if installer not found
    rm -f /usr/local/bin/lnos-shell.sh
    chsh -s /bin/bash root
fi

echo ""
echo "LnOS installer completed. Dropping to shell..."
echo ""

# Drop to bash shell
exec /bin/bash 