#!/bin/bash

# Set root password to 'lnos' for the live environment
echo 'root:lnos' | chpasswd

# Set timezone to UTC to prevent prompts
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Enable services for the live environment
systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable systemd-resolved

# Set up automatic login for root
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root %I \$TERM
EOF

# Copy the LnOS installer to root's home directory
mkdir -p /root/LnOS/scripts
cp /usr/local/bin/LnOS-installer.sh /root/LnOS/scripts/
cp -r /usr/share/lnos/pacman_packages /root/LnOS/scripts/

# Make installer executable
chmod +x /root/LnOS/scripts/LnOS-installer.sh

# Create a bashrc that auto-starts the installer
cat > /root/.bashrc << 'EOF'
#!/bin/bash

# Source the original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi

# Auto-start installer only on tty1 and only once
if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    # Mark that we've run the autostart
    touch /tmp/lnos-autostart-run
    
    # Wait a moment for the system to settle
    sleep 2
    
    # Run the autostart script
    /usr/local/bin/lnos-autostart.sh
fi
EOF