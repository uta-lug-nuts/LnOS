#!/bin/bash

# System-wide bashrc for LnOS
# This will be sourced by all bash sessions

# Only run autostart for root user and only once
if [[ $EUID -eq 0 ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    echo "System bashrc executed at $(date) on $(tty) for user $(whoami)" > /tmp/system-bashrc.log
    
    # Check if we're on tty1
    if [[ $(tty) == "/dev/tty1" ]]; then
        echo "On tty1, checking for autostart..." >> /tmp/system-bashrc.log
        
        # Mark that we've run the autostart
        touch /tmp/lnos-autostart-run
        echo "Created run flag" >> /tmp/system-bashrc.log
        
        # Wait a moment for the system to settle
        sleep 3
        
        # Run the setup script first
        echo "Running setup script..." >> /tmp/system-bashrc.log
        if [[ -f /usr/local/bin/setup-lnos-autostart.sh ]]; then
            /usr/local/bin/setup-lnos-autostart.sh >> /tmp/system-bashrc.log 2>&1
        else
            echo "Setup script not found!" >> /tmp/system-bashrc.log
        fi
        
        # Run the autostart script
        echo "Running autostart script..." >> /tmp/system-bashrc.log
        if [[ -f /usr/local/bin/lnos-autostart.sh ]]; then
            /usr/local/bin/lnos-autostart.sh >> /tmp/system-bashrc.log 2>&1
        else
            echo "ERROR: lnos-autostart.sh not found!" >> /tmp/system-bashrc.log
        fi
    else
        echo "Not on tty1, skipping autostart" >> /tmp/system-bashrc.log
    fi
fi 