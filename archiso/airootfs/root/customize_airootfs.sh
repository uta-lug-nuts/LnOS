#!/bin/bash

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