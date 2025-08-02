#!/bin/bash

# Set root password to 'lnos' for the live environment
echo 'root:lnos' | chpasswd

# Enable services for the live environment
systemctl enable NetworkManager
systemctl enable dhcpcd

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

# Create a simple bashrc that shows manual instructions if needed
cat > /root/.bashrc << 'EOF'
#!/bin/bash

# Source the original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi

# Show manual instructions if someone drops to shell
if [[ $(tty) == "/dev/tty1" ]]; then
    # Auto-detect architecture for manual instructions
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        TARGET="x86_64"
    elif [[ "$ARCH" == "aarch64" ]]; then
        TARGET="aarch64" 
    else
        TARGET="x86_64"  # fallback
    fi
    
    echo ""
    echo "=========================================="
    echo "Manual installer instructions:"
    echo "  cd /root/LnOS/scripts && ./LnOS-installer.sh --target=$TARGET"
    echo ""
    echo "For help: ./LnOS-installer.sh --help"
    echo "=========================================="
fi
EOF