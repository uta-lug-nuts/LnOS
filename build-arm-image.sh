#!/bin/bash

# Build script for LnOS ARM SD card image
# Usage: ./build-arm-image.sh [rpi4|generic]

set -e

DEVICE=${1:-rpi4}
OUTPUT_DIR="$(pwd)/out"
IMAGE_NAME="lnos-arm64-${DEVICE}-$(date +%Y.%m.%d).img"

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

# Check if running as root (required for image creation)
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root for image creation"
    exit 1
fi

print_status "Building LnOS ARM64 image for $DEVICE..."

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

# Check available disk space
print_status "Checking available disk space..."
df -h
check_disk_space

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a 1.5GB image file (will be expanded on first boot)
print_status "Creating 1.5GB base image file..."
if ! dd if=/dev/zero of="$OUTPUT_DIR/$IMAGE_NAME" bs=1M count=1536; then
    print_error "Failed to create image file! Check disk space."
    exit 1
fi

# Verify image was created and has correct size
if [ ! -f "$OUTPUT_DIR/$IMAGE_NAME" ] || [ $(stat -c%s "$OUTPUT_DIR/$IMAGE_NAME") -lt $((1536*1024*1024)) ]; then
    print_error "Image file creation failed or file is too small!"
    exit 1
fi

# Check disk space after image creation
print_status "Disk space after image creation:"
df -h
check_disk_space

# Set up loop device
print_status "Setting up loop device..."
LOOP_DEV=$(losetup -f --show "$OUTPUT_DIR/$IMAGE_NAME")

# Partition the image
print_status "Partitioning image..."
parted "$LOOP_DEV" mklabel msdos
parted "$LOOP_DEV" mkpart primary fat32 1MiB 257MiB
parted "$LOOP_DEV" mkpart primary ext4 257MiB 100%
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
        print_status "Creating unpartitioned filesystem instead..."
        
        # Create a simple unpartitioned image with just ext4
        mkfs.ext4 "$LOOP_DEV"
        
        # Mount and set up
        MOUNT_DIR="/tmp/lnos-arm-mount"
        mkdir -p "$MOUNT_DIR"
        mount "$LOOP_DEV" "$MOUNT_DIR"
        mkdir -p "$MOUNT_DIR/boot"
        
        # Skip boot partition setup for now
        SKIP_BOOT=1
    fi
else
    PART1="${LOOP_DEV}p1"
    PART2="${LOOP_DEV}p2"
fi

if [ "$SKIP_BOOT" != "1" ]; then
    # Format partitions
    print_status "Formatting partitions..."
    mkfs.fat -F32 "$PART1"
    mkfs.ext4 "$PART2"
    
    # Mount partitions
    print_status "Mounting partitions..."
    MOUNT_DIR="/tmp/lnos-arm-mount"
    mkdir -p "$MOUNT_DIR"
    mount "$PART2" "$MOUNT_DIR"
    mkdir -p "$MOUNT_DIR/boot"
    mount "$PART1" "$MOUNT_DIR/boot"
fi

# Download and extract Arch Linux ARM
print_status "Downloading Arch Linux ARM..."
case "$DEVICE" in
    "rpi4")
        TARBALL_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz"
        ;;
    "generic")
        TARBALL_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
        ;;
    *)
        print_error "Unsupported device: $DEVICE"
        exit 1
        ;;
esac

wget -O "/tmp/archlinuxarm.tar.gz" "$TARBALL_URL"

print_status "Extracting root filesystem..."
if ! tar -xzf "/tmp/archlinuxarm.tar.gz" -C "$MOUNT_DIR"; then
    print_error "Failed to extract root filesystem! Check disk space."
    print_error "Current disk space:"
    df -h
    exit 1
fi

# Clean up downloaded tarball to save space
print_status "Cleaning up downloaded tarball..."
rm -f "/tmp/archlinuxarm.tar.gz"

# Copy LnOS files
print_status "Installing LnOS components..."
mkdir -p "$MOUNT_DIR/root/LnOS/scripts"
cp -r scripts/pacman_packages "$MOUNT_DIR/root/LnOS/scripts/"
cp scripts/LnOS-installer.sh "$MOUNT_DIR/root/LnOS/scripts/"
cp scripts/expand-rootfs.sh "$MOUNT_DIR/root/LnOS/scripts/"
chmod +x "$MOUNT_DIR/root/LnOS/scripts/LnOS-installer.sh"
chmod +x "$MOUNT_DIR/root/LnOS/scripts/expand-rootfs.sh"

# Create first-boot expansion script
print_status "Creating first-boot partition expansion script..."
cat > "$MOUNT_DIR/usr/local/bin/expand-rootfs.sh" << 'EOF'
#!/bin/bash

# First-boot script to expand root partition to use entire SD card
# This script runs once on first boot to resize the root partition

EXPANSION_FLAG="/var/lib/lnos/rootfs-expanded"

# Check if we've already expanded
if [ -f "$EXPANSION_FLAG" ]; then
    echo "Root filesystem already expanded, skipping."
    exit 0
fi

echo "=========================================="
echo "    Expanding root filesystem to use"
echo "        entire SD card space..."
echo "=========================================="

# Get the root device
ROOT_DEV=$(findmnt -n -o SOURCE /)
if [ -z "$ROOT_DEV" ]; then
    echo "ERROR: Could not determine root device"
    exit 1
fi

# Get the partition number
PART_NUM=$(echo "$ROOT_DEV" | grep -o '[0-9]*$')
if [ -z "$PART_NUM" ]; then
    echo "ERROR: Could not determine partition number"
    exit 1
fi

# Get the base device (remove partition number)
BASE_DEV=$(echo "$ROOT_DEV" | sed 's/[0-9]*$//')
if [ -z "$BASE_DEV" ]; then
    echo "ERROR: Could not determine base device"
    exit 1
fi

echo "Root device: $ROOT_DEV"
echo "Base device: $BASE_DEV"
echo "Partition: $PART_NUM"

# Expand the partition to use all available space
echo "Expanding partition $PART_NUM to use entire device..."
parted "$BASE_DEV" resizepart "$PART_NUM" 100%

# Refresh partition table
partprobe "$BASE_DEV"

# Wait a moment for the kernel to recognize the change
sleep 2

# Expand the filesystem to use the new partition size
echo "Expanding filesystem..."
if command -v resize2fs >/dev/null 2>&1; then
    resize2fs "$ROOT_DEV"
else
    echo "WARNING: resize2fs not available, filesystem expansion skipped"
fi

# Create flag file to prevent re-expansion
mkdir -p "$(dirname "$EXPANSION_FLAG")"
touch "$EXPANSION_FLAG"

echo "=========================================="
echo "    Root filesystem expansion complete!"
echo "=========================================="

# Remove this script from startup
systemctl disable expand-rootfs.service 2>/dev/null || true
rm -f /etc/systemd/system/expand-rootfs.service

echo "Rebooting to ensure all changes take effect..."
sleep 3
reboot
EOF

chmod +x "$MOUNT_DIR/usr/local/bin/expand-rootfs.sh"

# Create systemd service for first-boot expansion
cat > "$MOUNT_DIR/etc/systemd/system/expand-rootfs.service" << 'EOF'
[Unit]
Description=Expand root filesystem on first boot
After=local-fs.target network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/expand-rootfs.sh
RemainAfterExit=yes
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF

# Configure system settings
print_status "Configuring system settings..."

# Set default timezone
ln -sf /usr/share/zoneinfo/UTC "$MOUNT_DIR/etc/localtime"

# Configure pacman repositories
cat > "$MOUNT_DIR/etc/pacman.conf" << 'EOF'
#
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives

#
# GENERAL OPTIONS
#
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.
#RootDir     = /
#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
HoldPkg     = pacman glibc
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
#CleanMethod = KeepInstalled
Architecture = aarch64

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
#UseSyslog
#Color
#NoProgressBar
CheckSpace
#VerbosePkgLists
ParallelDownloads = 5

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = DatabaseRequired
LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#

# Include other repositories from a file
Include = /etc/pacman.d/mirrorlist

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

# Enable the expansion service
chroot "$MOUNT_DIR" systemctl enable expand-rootfs.service

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
    
    # Run the installer directly
    if [[ -f /root/LnOS/scripts/LnOS-installer.sh ]]; then
        cd /root/LnOS/scripts
        chmod +x ./LnOS-installer.sh
        echo "Starting LnOS installer..."
        ./LnOS-installer.sh --target=aarch64
        
        # Remove the autostart from bashrc after it runs
        sed -i '/# Simple LnOS Autostart/,/fi$/d' /root/.bashrc
    fi
fi
EOF

# Configure networking
print_status "Configuring networking..."

# Enable systemd-networkd
chroot "$MOUNT_DIR" systemctl enable systemd-networkd
chroot "$MOUNT_DIR" systemctl enable systemd-resolved

# Create network configuration
mkdir -p "$MOUNT_DIR/etc/systemd/network"
cat > "$MOUNT_DIR/etc/systemd/network/20-wired.network" << 'EOF'
[Match]
Name=eth0

[Network]
DHCP=yes
EOF

# Enable NetworkManager (if available)
if chroot "$MOUNT_DIR" systemctl --quiet is-enabled NetworkManager 2>/dev/null; then
    chroot "$MOUNT_DIR" systemctl enable NetworkManager
else
    print_warning "NetworkManager not found, using systemd-networkd"
fi

# Clean up
print_status "Cleaning up..."
if [ "$SKIP_BOOT" != "1" ]; then
    umount "$MOUNT_DIR/boot" 2>/dev/null || true
fi
umount "$MOUNT_DIR" 2>/dev/null || true
rmdir "$MOUNT_DIR" 2>/dev/null || true

# Clean up device mappings
if command -v kpartx >/dev/null 2>&1; then
    kpartx -dv "$LOOP_DEV" 2>/dev/null || true
fi

losetup -d "$LOOP_DEV" 2>/dev/null || true
rm -f "/tmp/archlinuxarm.tar.gz"

print_status "ARM64 image created: $OUTPUT_DIR/$IMAGE_NAME"
print_status "To write to SD card: dd if=$OUTPUT_DIR/$IMAGE_NAME of=/dev/sdX bs=4M status=progress"
print_status "Note: The 1.5GB image (256MB boot + 1.3GB root) will automatically expand to use the entire SD card space on first boot"

# Final disk space check
print_status "Final disk space check:"
df -h