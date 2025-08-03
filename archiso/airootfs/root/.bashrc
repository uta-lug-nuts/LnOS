#!/bin/bash

# Debug: Always log that bashrc ran
echo "Bashrc executed at $(date) on $(tty)" > /tmp/bashrc-executed.log

# Source the original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi

# Auto-start LnOS installer only on tty1 and only once
echo "Checking autostart conditions..." >> /tmp/bashrc-executed.log
echo "Current TTY: $(tty)" >> /tmp/bashrc-executed.log
echo "Run flag exists: $([[ -f /tmp/lnos-autostart-run ]] && echo 'yes' || echo 'no')" >> /tmp/bashrc-executed.log

if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    echo "STARTING AUTOSTART at $(date)" > /tmp/bashrc-start.log
    echo "Starting LnOS autostart on tty1..." >> /tmp/bashrc-executed.log
    
    # Mark that we've run the autostart
    touch /tmp/lnos-autostart-run
    echo "Created run flag" >> /tmp/bashrc-start.log
    
    # Wait a moment for the system to settle
    sleep 3
    
    # Run the setup script first
    echo "Running setup script..." >> /tmp/bashrc-start.log
    if [[ -f /usr/local/bin/setup-lnos-autostart.sh ]]; then
        /usr/local/bin/setup-lnos-autostart.sh >> /tmp/bashrc-start.log 2>&1
    else
        echo "Setup script not found!" >> /tmp/bashrc-start.log
    fi
    
    # Run the autostart script
    echo "Running autostart script..." >> /tmp/bashrc-start.log
    if [[ -f /usr/local/bin/lnos-autostart.sh ]]; then
        /usr/local/bin/lnos-autostart.sh >> /tmp/bashrc-start.log 2>&1
    else
        echo "ERROR: lnos-autostart.sh not found!" > /tmp/bashrc-error.log
    fi
else
    echo "SKIPPING AUTOSTART" > /tmp/bashrc-skip.log
    echo "Skipping autostart - tty: $(tty), run flag: $([[ -f /tmp/lnos-autostart-run ]] && echo 'exists' || echo 'missing')" >> /tmp/bashrc-skip.log
fi 