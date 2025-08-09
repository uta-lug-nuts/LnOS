#!/bin/bash

# Setup script for LnOS autostart
# This script runs during boot to ensure autostart is properly configured

echo "Setting up LnOS autostart..." > /tmp/setup-lnos.log

# Enable the autostart service if it exists
if [[ -f /etc/systemd/system/lnos-autostart.service ]]; then
    echo "Enabling lnos-autostart.service..." >> /tmp/setup-lnos.log
    systemctl enable lnos-autostart.service
    echo "Service enabled successfully" >> /tmp/setup-lnos.log
else
    echo "ERROR: lnos-autostart.service not found!" >> /tmp/setup-lnos.log
fi

# Create the LnOS directory structure if it doesn't exist
if [[ ! -d /root/LnOS/scripts ]]; then
    echo "Creating LnOS directory structure..." >> /tmp/setup-lnos.log
    mkdir -p /root/LnOS/scripts
    cp /usr/local/bin/LnOS-installer.sh /root/LnOS/scripts/ 2>/dev/null || echo "Failed to copy installer" >> /tmp/setup-lnos.log
    chmod +x /root/LnOS/scripts/LnOS-installer.sh 2>/dev/null || echo "Failed to make installer executable" >> /tmp/setup-lnos.log
fi

# Create pacman_packages directory if it doesn't exist
if [[ ! -d /root/LnOS/scripts/pacman_packages ]]; then
    echo "Creating pacman_packages directory..." >> /tmp/setup-lnos.log
    mkdir -p /root/LnOS/scripts/pacman_packages
fi

echo "LnOS autostart setup completed" >> /tmp/setup-lnos.log 