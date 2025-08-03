#!/bin/bash

# Source the original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi

# Auto-start LnOS installer only on tty1 and only once
if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    echo "Starting LnOS autostart on tty1..." > /tmp/bashrc-start.log
    
    # Mark that we've run the autostart
    touch /tmp/lnos-autostart-run
    
    # Wait a moment for the system to settle
    sleep 3
    
    # Run the setup script first
    if [[ -f /usr/local/bin/setup-lnos-autostart.sh ]]; then
        /usr/local/bin/setup-lnos-autostart.sh
    fi
    
    # Run the autostart script
    if [[ -f /usr/local/bin/lnos-autostart.sh ]]; then
        /usr/local/bin/lnos-autostart.sh
    else
        echo "ERROR: lnos-autostart.sh not found!" > /tmp/bashrc-error.log
    fi
else
    echo "Skipping autostart - tty: $(tty), run flag: $([[ -f /tmp/lnos-autostart-run ]] && echo 'exists' || echo 'missing')" > /tmp/bashrc-skip.log
fi 