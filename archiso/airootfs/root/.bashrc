#!/bin/bash

# Simple LnOS Autostart - run once on tty1
if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    # Mark that we've run
    touch /tmp/lnos-autostart-run
    
    # Wait a moment for system to settle
    sleep 2
    
    # Run the autostart script directly
    if [[ -f /usr/local/bin/lnos-autostart.sh ]]; then
        /usr/local/bin/lnos-autostart.sh
    fi
fi 