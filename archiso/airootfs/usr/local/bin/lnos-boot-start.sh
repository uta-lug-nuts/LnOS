#!/bin/bash

# LnOS Boot Autostart Script
# This runs at system boot time

echo "LnOS boot script starting at $(date)" > /tmp/lnos-boot.log

# Wait for network and system to be ready
sleep 5

# Test network connectivity
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "Network is up" >> /tmp/lnos-boot.log
else
    echo "Network is down, waiting..." >> /tmp/lnos-boot.log
    sleep 10
fi

# Run the setup script first
echo "Running setup script..." >> /tmp/lnos-boot.log
if [[ -f /usr/local/bin/setup-lnos-autostart.sh ]]; then
    /usr/local/bin/setup-lnos-autostart.sh >> /tmp/lnos-boot.log 2>&1
else
    echo "Setup script not found!" >> /tmp/lnos-boot.log
fi

# Run the autostart script
echo "Running autostart script..." >> /tmp/lnos-boot.log
if [[ -f /usr/local/bin/lnos-autostart.sh ]]; then
    /usr/local/bin/lnos-autostart.sh >> /tmp/lnos-boot.log 2>&1
else
    echo "ERROR: lnos-autostart.sh not found!" >> /tmp/lnos-boot.log
fi

echo "LnOS boot script completed at $(date)" >> /tmp/lnos-boot.log 