#!/bin/bash

# Simple LnOS autostart - run once when root logs in
if [[ ! -f /tmp/lnos-autostart-run ]]; then
    touch /tmp/lnos-autostart-run
    
    # Wait a moment for system to settle
    sleep 2
    
    # Run the installer directly
    if [[ -f /root/LnOS/scripts/LnOS-installer.sh ]]; then
        cd /root/LnOS/scripts
        chmod +x ./LnOS-installer.sh
        ./LnOS-installer.sh --target=x86_64
    fi
fi 