#!/bin/bash

# Debug: Log that customize script is running
echo "LnOS customize script starting at $(date)" > /tmp/customize-debug.log

# Set root password to 'lnos' for the live environment
echo 'root:lnos' | chpasswd

# Set timezone to UTC to prevent prompts
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Configure pacman repositories and keyring
echo "Configuring pacman repositories..."
pacman-key --init
pacman-key --populate archlinux

# Force replace the mirrorlist with our reliable one
echo "Replacing mirrorlist with reliable mirrors..."
cat > /etc/pacman.d/mirrorlist << 'EOF'
# Arch Linux mirrorlist for LnOS ISO
# Using mirrors that support core and extra repositories

Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.leaseweb.net/archlinux/$repo/os/$arch
EOF

# Update package databases
echo "Updating package databases..."
pacman -Syy --noconfirm

# Test repository connectivity
echo "Testing repository connectivity..."
if ! pacman -Sy --noconfirm >/dev/null 2>&1; then
    echo "WARNING: Repository test failed, will retry during runtime..."
fi

# Enable services for the live environment
systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable systemd-resolved

# Set up automatic login for root with autostart
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root %I \$TERM
EOF

# Also set the default shell for root to our LnOS shell
chsh -s /usr/local/bin/lnos-shell.sh root

# Copy the LnOS installer to root's home directory
mkdir -p /root/LnOS/scripts
cp /usr/local/bin/LnOS-installer.sh /root/LnOS/scripts/

# Copy pacman packages if they exist
if [[ -d "/usr/share/lnos/pacman_packages" ]]; then
    cp -r /usr/share/lnos/pacman_packages /root/LnOS/scripts/
else
    echo "WARNING: /usr/share/lnos/pacman_packages not found, creating empty directory"
    mkdir -p /root/LnOS/scripts/pacman_packages
fi

# Make installer executable
chmod +x /root/LnOS/scripts/LnOS-installer.sh

# Create a marker file to show the customize script completed
echo "Customize script completed at $(date)" > /tmp/customize-completed
echo "Customize script completed successfully" >> /tmp/customize-debug.log

# Create a systemd service for auto-starting the installer
echo "Creating systemd service..." >> /tmp/customize-debug.log
cat > /etc/systemd/system/lnos-autostart.service << 'EOF'
[Unit]
Description=LnOS Auto-start Installer
After=network-online.target
Wants=network-online.target
ConditionPathExists=/usr/local/bin/lnos-autostart.sh

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lnos-autostart.sh
StandardInput=tty
StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Disable systemd services since they don't work well with terminal output
echo "Disabling systemd services for terminal output..." >> /tmp/customize-debug.log
systemctl disable lnos-autostart.service 2>/dev/null || true
systemctl disable lnos-boot.service 2>/dev/null || true
echo "Systemd services disabled, using shell-based method" >> /tmp/customize-debug.log

# Note: Using shell-based autostart approach, not bashrc
echo "Using shell-based autostart approach" >> /tmp/customize-debug.log