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

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a 4GB image file
print_status "Creating 4GB image file..."
dd if=/dev/zero of="$OUTPUT_DIR/$IMAGE_NAME" bs=1M count=4096

# Set up loop device
print_status "Setting up loop device..."
LOOP_DEV=$(losetup -f --show "$OUTPUT_DIR/$IMAGE_NAME")

# Partition the image
print_status "Partitioning image..."
parted "$LOOP_DEV" mklabel msdos
parted "$LOOP_DEV" mkpart primary fat32 1MiB 513MiB
parted "$LOOP_DEV" mkpart primary ext4 513MiB 100%
parted "$LOOP_DEV" set 1 boot on

# Refresh partition table
partprobe "$LOOP_DEV"

# Format partitions
print_status "Formatting partitions..."
mkfs.fat -F32 "${LOOP_DEV}p1"
mkfs.ext4 "${LOOP_DEV}p2"

# Mount partitions
print_status "Mounting partitions..."
MOUNT_DIR="/tmp/lnos-arm-mount"
mkdir -p "$MOUNT_DIR"
mount "${LOOP_DEV}p2" "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR/boot"
mount "${LOOP_DEV}p1" "$MOUNT_DIR/boot"

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
tar -xzf "/tmp/archlinuxarm.tar.gz" -C "$MOUNT_DIR"

# Copy LnOS files
print_status "Installing LnOS components..."
mkdir -p "$MOUNT_DIR/root/LnOS/scripts"
cp -r scripts/pacman_packages "$MOUNT_DIR/root/LnOS/scripts/"
cp scripts/LnOS-installer.sh "$MOUNT_DIR/root/LnOS/scripts/"
chmod +x "$MOUNT_DIR/root/LnOS/scripts/LnOS-installer.sh"

# Create auto-start script
cat > "$MOUNT_DIR/root/.bashrc" << 'EOF'
#!/bin/bash

echo "=========================================="
echo "      Welcome to LnOS ARM64 Environment"
echo "=========================================="
echo ""
echo "To start the installation, run:"
echo "  cd /root/LnOS/scripts && ./LnOS-installer.sh --target=aarch64"
echo ""
echo "For help, run:"
echo "  ./LnOS-installer.sh --help"
echo ""
echo "Network configuration may be needed:"
echo "  systemctl enable NetworkManager"
echo "  systemctl start NetworkManager"
echo "=========================================="
echo ""

# Source original bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi
EOF

# Enable NetworkManager
print_status "Configuring services..."
chroot "$MOUNT_DIR" systemctl enable NetworkManager

# Clean up
print_status "Cleaning up..."
umount "$MOUNT_DIR/boot"
umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"
losetup -d "$LOOP_DEV"
rm -f "/tmp/archlinuxarm.tar.gz"

print_status "ARM64 image created: $OUTPUT_DIR/$IMAGE_NAME"
print_status "To write to SD card: dd if=$OUTPUT_DIR/$IMAGE_NAME of=/dev/sdX bs=4M status=progress"