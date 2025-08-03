#!/bin/bash

# Simple LnOS Autostart - run once on tty1
if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    # Mark that we've run
    touch /tmp/lnos-autostart-run
    
    # Wait a moment for system to settle
    sleep 2
    
    # Run the installer directly
    if [[ -f /root/LnOS/scripts/LnOS-installer.sh ]]; then
        cd /root/LnOS/scripts
        chmod +x ./LnOS-installer.sh
        echo "Starting LnOS installer..."
        ./LnOS-installer.sh --target=x86_64
        
        # Remove the autostart from bashrc after it runs
        sed -i '/# Simple LnOS Autostart/,/fi$/d' /root/.bashrc
    fi
fi 