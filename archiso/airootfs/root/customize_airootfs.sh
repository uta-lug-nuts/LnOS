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

# Create a welcome message and auto-start installer option
cat > /root/.bashrc << 'EOF'
#!/bin/bash

# Source the original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi

# Only show welcome on first login (tty1)
if [[ $(tty) == "/dev/tty1" ]]; then
    echo "=========================================="
    echo "      Welcome to LnOS Live Environment"
    echo "=========================================="
    echo ""
    echo "Network should be automatically configured."
    echo ""
    echo "Options:"
    echo "  1. Start LnOS installer automatically"
    echo "  2. Drop to shell"
    echo ""
    
    # Ask user if they want to start installer automatically
    read -p "Start installer now? [Y/n]: " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        echo "Starting LnOS installer..."
        cd /root/LnOS/scripts
        ./LnOS-installer.sh --target=x86_64
    else
        echo "Dropped to shell. To start installer later, run:"
        echo "  cd /root/LnOS/scripts && ./LnOS-installer.sh --target=x86_64"
        echo ""
        echo "For help: ./LnOS-installer.sh --help"
        echo "=========================================="
    fi
fi
EOF