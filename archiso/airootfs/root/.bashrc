#!/bin/bash

# Simple LnOS Autostart - run once on tty1
if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    # Mark that we've run
    touch /tmp/lnos-autostart-run
    
    # Remove autostart from bashrc immediately
    sed -i '/# Simple LnOS Autostart/,/fi$/d' /root/.bashrc
    
    # Wait a moment for system to settle
    sleep 2
    
    # Run the installer directly
    if [[ -f /root/LnOS/scripts/LnOS-installer.sh ]]; then
        cd /root/LnOS/scripts
        chmod +x ./LnOS-installer.sh
        echo "Starting LnOS installer..."
        ./LnOS-installer.sh --target=x86_64
    else
        echo "ERROR: Installer not found!"
        echo "Available files in /root/LnOS/scripts/:"
        ls -la /root/LnOS/scripts/ 2>/dev/null || echo "Directory not found"
    fi
fi 