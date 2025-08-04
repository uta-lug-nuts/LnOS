#!/bin/bash

# Simple LnOS Autostart - run once on tty1
if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    # Mark that we've run
    touch /tmp/lnos-autostart-run
    
    # Debug: Log that we're starting
    echo "Bashrc autostart triggered at $(date)" > /tmp/bashrc-debug.log
    
    # Wait a moment for system to settle
    sleep 2
    
    # Run the installer directly with explicit terminal output
    if [[ -f /root/LnOS/scripts/LnOS-installer.sh ]]; then
        cd /root/LnOS/scripts
        chmod +x ./LnOS-installer.sh
        echo "Starting LnOS installer..." | tee /dev/tty
        echo "Starting LnOS installer..." >> /tmp/bashrc-debug.log
        
        # Remove the autostart from bashrc immediately when installer starts
        sed -i '/# Simple LnOS Autostart/,/fi$/d' /root/.bashrc
        
        # Run installer with explicit terminal output
        ./LnOS-installer.sh --target=x86_64 2>&1 | tee /dev/tty
        
        echo "Installer completed" >> /tmp/bashrc-debug.log
    else
        echo "ERROR: Installer not found!" | tee /dev/tty
        echo "ERROR: Installer not found!" >> /tmp/bashrc-debug.log
        
        # Remove the autostart from bashrc even if installer not found
        sed -i '/# Simple LnOS Autostart/,/fi$/d' /root/.bashrc
    fi
fi 