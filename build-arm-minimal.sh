#!/bin/bash

# Build script for minimal LnOS ARM image (similar to x86_64 ISO approach)
# Usage: ./build-arm-minimal.sh [rpi4|generic]

set -e

DEVICE=${1:-rpi4}
OUTPUT_DIR="$(pwd)/out"
IMAGE_NAME="lnos-arm64-${DEVICE}-minimal-$(date +%Y.%m.%d).img"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check disk space and fail if too low
check_disk_space() {
    local min_space_gb=3
    local available_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    print_status "Available disk space: ${available_gb}GB"
    if [ "$available_gb" -lt "$min_space_gb" ]; then
        print_error "Insufficient disk space! Only ${available_gb}GB available, need at least ${min_space_gb}GB"
        exit 1
    fi
}

print_status "Building minimal LnOS ARM64 image for $DEVICE..."

# Check available disk space
print_status "Checking available disk space..."
df -h
check_disk_space

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a 512MB image file (minimal size)
print_status "Creating 512MB minimal image file..."
if ! dd if=/dev/zero of="$OUTPUT_DIR/$IMAGE_NAME" bs=1M count=512; then
    print_error "Failed to create image file! Check disk space."
    exit 1
fi

# Verify image was created and has correct size
if [ ! -f "$OUTPUT_DIR/$IMAGE_NAME" ] || [ $(stat -c%s "$OUTPUT_DIR/$IMAGE_NAME") -lt $((512*1024*1024)) ]; then
    print_error "Image file creation failed or file is too small!"
    exit 1
fi

# Check disk space after image creation
print_status "Disk space after image creation:"
df -h
check_disk_space

# Set up loop device
print_status "Setting up loop device..."
LOOP_DEV=$(losetup --find --show "$OUTPUT_DIR/$IMAGE_NAME")

# Partition the image
print_status "Partitioning image..."
parted "$LOOP_DEV" mklabel msdos
parted "$LOOP_DEV" mkpart primary fat32 1MiB 129MiB
parted "$LOOP_DEV" mkpart primary ext4 129MiB 100%
parted "$LOOP_DEV" set 1 boot on

# Refresh partition table and wait for device nodes
partprobe "$LOOP_DEV"
sleep 2

# Check if partition devices exist, create them if needed
if [ ! -e "${LOOP_DEV}p1" ]; then
    # Try alternative method using kpartx
    if command -v kpartx >/dev/null 2>&1; then
        print_status "Using kpartx to create partition devices..."
        kpartx -av "$LOOP_DEV"
        PART1="/dev/mapper/$(basename $LOOP_DEV)p1"
        PART2="/dev/mapper/$(basename $LOOP_DEV)p2"
    else
        print_error "Cannot create partition devices. Container limitations."
        exit 1
    fi
else
    PART1="${LOOP_DEV}p1"
    PART2="${LOOP_DEV}p2"
fi

# Format partitions
print_status "Formatting partitions..."
mkfs.fat -F32 "$PART1"
mkfs.ext4 "$PART2"

# Mount partitions
print_status "Mounting partitions..."
MOUNT_DIR="/tmp/lnos-arm-minimal-mount"
mkdir -p "$MOUNT_DIR"
mount "$PART2" "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR/boot"
mount "$PART1" "$MOUNT_DIR/boot"

# Create minimal root filesystem structure
print_status "Creating minimal root filesystem..."
mkdir -p "$MOUNT_DIR"/{bin,boot,dev,etc,home,lib,lib64,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}

# Create essential directories
mkdir -p "$MOUNT_DIR"/usr/{bin,lib,lib64,sbin,share,include}
mkdir -p "$MOUNT_DIR"/var/{cache,lib,log,run,spool,tmp}
mkdir -p "$MOUNT_DIR"/etc/{systemd/system,network,ssh}

# Download minimal kernel and firmware for the device
print_status "Downloading minimal kernel and firmware..."
case "$DEVICE" in
    "rpi4")
        # Download Raspberry Pi 4 specific kernel and firmware
        wget -O "/tmp/linux-rpi4.tar.gz" "https://archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz"
        # Extract only kernel and firmware
        tar -xzf "/tmp/linux-rpi4.tar.gz" -C "/tmp" --wildcards "boot/*" "lib/modules/*" "lib/firmware/*"
        cp -r /tmp/boot/* "$MOUNT_DIR/boot/"
        cp -r /tmp/lib/modules "$MOUNT_DIR/lib/"
        cp -r /tmp/lib/firmware "$MOUNT_DIR/lib/"
        rm -rf /tmp/boot /tmp/lib /tmp/linux-rpi4.tar.gz
        ;;
    "generic")
        # Download generic ARM64 kernel
        wget -O "/tmp/linux-generic.tar.gz" "https://archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
        # Extract only kernel and firmware
        tar -xzf "/tmp/linux-generic.tar.gz" -C "/tmp" --wildcards "boot/*" "lib/modules/*" "lib/firmware/*"
        cp -r /tmp/boot/* "$MOUNT_DIR/boot/"
        cp -r /tmp/lib/modules "$MOUNT_DIR/lib/"
        cp -r /tmp/lib/firmware "$MOUNT_DIR/lib/"
        rm -rf /tmp/boot /tmp/lib /tmp/linux-generic.tar.gz
        ;;
    *)
        print_error "Unsupported device: $DEVICE"
        exit 1
        ;;
esac

# Create minimal system files
print_status "Creating minimal system configuration..."

# Create basic /etc/passwd
cat > "$MOUNT_DIR/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/bash
EOF

# Create basic /etc/group
cat > "$MOUNT_DIR/etc/group" << 'EOF'
root:x:0:
EOF

# Create basic /etc/hosts
cat > "$MOUNT_DIR/etc/hosts" << 'EOF'
127.0.0.1 localhost
::1 localhost
EOF

# Create basic /etc/resolv.conf
cat > "$MOUNT_DIR/etc/resolv.conf" << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# Note: Using shell-based autostart instead of systemd service

# Create a simple bashrc with autostart
cat > "$MOUNT_DIR/root/.bashrc" << 'EOF'
#!/bin/bash

# Source original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi

# Simple LnOS Autostart - run once on tty1
if [[ $(tty) == "/dev/tty1" ]] && [[ ! -f /tmp/lnos-autostart-run ]]; then
    # Mark that we've run
    touch /tmp/lnos-autostart-run
    
    # Wait a moment for system to settle
    sleep 2
    
    # Enable and start network services
    systemctl enable systemd-networkd
    systemctl enable systemd-resolved
    systemctl start systemd-networkd
    systemctl start systemd-resolved
    
    echo "Network services started."
    echo ""
    
    # Run the installer directly
    if [[ -f /root/LnOS/scripts/LnOS-installer.sh ]]; then
        cd /root/LnOS/scripts
        chmod +x ./LnOS-installer.sh
        echo "Starting LnOS installer..."
        ./LnOS-installer.sh --target=aarch64
        
        # Remove the autostart from bashrc after it runs
        sed -i '/# Simple LnOS Autostart/,/fi$/d' /root/.bashrc
    else
        echo "ERROR: LnOS installer not found!"
        echo "This is a minimal ARM image for LnOS installation."
        echo ""
        echo "To install LnOS, you need to:"
        echo "1. Download the full LnOS installer"
        echo "2. Run the installation process"
        echo ""
        echo "For more information, visit: https://github.com/uta-lug-nuts/LnOS"
        
        # Remove the autostart from bashrc even if installer not found
        sed -i '/# Simple LnOS Autostart/,/fi$/d' /root/.bashrc
    fi
fi
EOF

# Create basic initramfs
print_status "Creating minimal initramfs..."
mkdir -p "$MOUNT_DIR/boot/initramfs"
cat > "$MOUNT_DIR/boot/initramfs/init" << 'EOF'
#!/bin/sh

# Minimal init script
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Mount root filesystem
mount -t ext4 /dev/mmcblk0p2 /mnt/root

# Switch to root filesystem
exec switch_root /mnt/root /sbin/init
EOF

chmod +x "$MOUNT_DIR/boot/initramfs/init"

# Create boot configuration
case "$DEVICE" in
    "rpi4")
        cat > "$MOUNT_DIR/boot/cmdline.txt" << 'EOF'
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait
EOF
        ;;
    "generic")
        cat > "$MOUNT_DIR/boot/cmdline.txt" << 'EOF'
console=ttyS0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait
EOF
        ;;
esac

# Configure pacman repositories for minimal image
print_status "Configuring pacman repositories..."
mkdir -p "$MOUNT_DIR/etc/pacman.d"

# Create pacman.conf
cat > "$MOUNT_DIR/etc/pacman.conf" << 'EOF'
#
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives

#
# GENERAL OPTIONS
#
[options]
HoldPkg     = pacman glibc
Architecture = aarch64

# Misc options
CheckSpace
ParallelDownloads = 5

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = DatabaseRequired
LocalFileSigLevel = Optional

#
# REPOSITORIES
#
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist
EOF

# Create mirrorlist
cat > "$MOUNT_DIR/etc/pacman.d/mirrorlist" << 'EOF'
# Arch Linux ARM mirrorlist

# Primary mirrors
Server = https://mirror.archlinuxarm.org/$arch/$repo
Server = https://uk.mirror.archlinuxarm.org/$arch/$repo
Server = https://us.mirror.archlinuxarm.org/$arch/$repo
Server = https://sg.mirror.archlinuxarm.org/$arch/$repo
EOF

# Initialize pacman keyring
chroot "$MOUNT_DIR" pacman-key --init
chroot "$MOUNT_DIR" pacman-key --populate archlinuxarm

# Copy LnOS installer scripts
print_status "Installing LnOS components..."
mkdir -p "$MOUNT_DIR/root/LnOS/scripts"
cp -r scripts/pacman_packages "$MOUNT_DIR/root/LnOS/scripts/"
cp scripts/LnOS-installer.sh "$MOUNT_DIR/root/LnOS/scripts/"
chmod +x "$MOUNT_DIR/root/LnOS/scripts/LnOS-installer.sh"

# Create welcome message
cat > "$MOUNT_DIR/root/LnOS/README.txt" << 'EOF'
LnOS Minimal ARM Image
======================

This is a minimal ARM image for LnOS installation.

To install LnOS:
1. Boot this image on your ARM device
2. Run: cd /root/LnOS/scripts && ./LnOS-installer.sh --target=aarch64
3. Follow the installation prompts

For more information: https://github.com/uta-lug-nuts/LnOS
EOF

# Unmount everything
print_status "Unmounting partitions..."
umount "$MOUNT_DIR/boot"
umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"

# Clean up loop device
losetup -d "$LOOP_DEV"

print_status "Minimal ARM64 image created: $OUTPUT_DIR/$IMAGE_NAME"
print_status "To write to SD card: dd if=$OUTPUT_DIR/$IMAGE_NAME of=/dev/sdX bs=4M status=progress"
print_status "Note: This is a minimal 512MB image (128MB boot + 384MB root) for LnOS installation"

# Final disk space check
print_status "Final disk space check:"
df -h 