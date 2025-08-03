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

# Enable the autostart service
echo "Enabling systemd service..." >> /tmp/customize-debug.log
systemctl enable lnos-autostart.service
echo "Systemd service enabled" >> /tmp/customize-debug.log

# Enable the boot service as well
echo "Enabling boot service..." >> /tmp/customize-debug.log
systemctl enable lnos-boot.service
echo "Boot service enabled" >> /tmp/customize-debug.log

# Also keep the bashrc approach as backup
echo "Creating bashrc backup..." >> /tmp/customize-debug.log
cat > /root/.bashrc << 'EOF'
#!/bin/bash

# Debug: Log bashrc execution
echo "Bashrc executed at $(date)" >> /tmp/bashrc-debug.log

# Source the original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi

# Auto-start installer only on tty1 and only once (backup method)
if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    echo "Bashrc: Starting autostart on tty1" >> /tmp/bashrc-debug.log
    # Mark that we've run the autostart
    touch /tmp/lnos-autostart-run
    
    # Wait a moment for the system to settle
    sleep 2
    
    # Run the autostart script
    /usr/local/bin/lnos-autostart.sh
else
    echo "Bashrc: Skipping autostart - tty: $(tty), run flag: $([[ -f /tmp/lnos-autostart-run ]] && echo 'exists' || echo 'missing')" >> /tmp/bashrc-debug.log
fi
EOF
echo "Bashrc created" >> /tmp/customize-debug.log