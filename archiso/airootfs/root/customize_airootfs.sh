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

# Create a welcome message
cat > /root/.bashrc << 'EOF'
#!/bin/bash

echo "=========================================="
echo "      Welcome to LnOS Live Environment"
echo "=========================================="
echo ""
echo "To start the installation, run:"
echo "  cd /root/LnOS/scripts && ./LnOS-installer.sh --target=x86_64"
echo ""
echo "For help, run:"
echo "  ./LnOS-installer.sh --help"
echo ""
echo "Network should be automatically configured."
echo "=========================================="
echo ""

# Source the original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi
EOF