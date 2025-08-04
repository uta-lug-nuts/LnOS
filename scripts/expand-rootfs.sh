#!/bin/bash

# Manual root filesystem expansion script for LnOS ARM images
# This script expands the root partition to use the entire SD card space

set -e

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

print_status "LnOS Root Filesystem Expansion Tool"
echo "=========================================="

# Get the root device
ROOT_DEV=$(findmnt -n -o SOURCE /)
if [ -z "$ROOT_DEV" ]; then
    print_error "Could not determine root device"
    exit 1
fi

# Get the partition number
PART_NUM=$(echo "$ROOT_DEV" | grep -o '[0-9]*$')
if [ -z "$PART_NUM" ]; then
    print_error "Could not determine partition number"
    exit 1
fi

# Get the base device (remove partition number)
BASE_DEV=$(echo "$ROOT_DEV" | sed 's/[0-9]*$//')
if [ -z "$BASE_DEV" ]; then
    print_error "Could not determine base device"
    exit 1
fi

echo "Root device: $ROOT_DEV"
echo "Base device: $BASE_DEV"
echo "Partition: $PART_NUM"
echo ""

# Check current partition size
CURRENT_SIZE=$(parted "$BASE_DEV" unit MiB print | grep "^ $PART_NUM" | awk '{print $4}')
print_status "Current partition size: $CURRENT_SIZE"

# Check device size
DEVICE_SIZE=$(parted "$BASE_DEV" unit MiB print | grep "^Disk $BASE_DEV" | awk '{print $3}')
print_status "Device size: $DEVICE_SIZE"

# Check if expansion is needed
if [ "$CURRENT_SIZE" = "$DEVICE_SIZE" ]; then
    print_status "Partition already uses full device size. No expansion needed."
    exit 0
fi

# Confirm expansion
echo ""
print_warning "This will expand the root partition to use the entire device space."
print_warning "The system will reboot after expansion to ensure all changes take effect."
echo ""
read -p "Continue with expansion? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Expansion cancelled."
    exit 0
fi

print_status "Starting partition expansion..."

# Expand the partition to use all available space
print_status "Expanding partition $PART_NUM to use entire device..."
parted "$BASE_DEV" resizepart "$PART_NUM" 100%

# Refresh partition table
print_status "Refreshing partition table..."
partprobe "$BASE_DEV"

# Wait a moment for the kernel to recognize the change
sleep 2

# Expand the filesystem to use the new partition size
print_status "Expanding filesystem..."
if command -v resize2fs >/dev/null 2>&1; then
    resize2fs "$ROOT_DEV"
    print_status "Filesystem expansion completed successfully!"
else
    print_error "resize2fs not available. Filesystem expansion failed."
    exit 1
fi

# Verify the expansion
NEW_SIZE=$(parted "$BASE_DEV" unit MiB print | grep "^ $PART_NUM" | awk '{print $4}')
print_status "New partition size: $NEW_SIZE"

echo ""
print_status "=========================================="
print_status "    Root filesystem expansion complete!"
print_status "=========================================="
print_status "Rebooting in 10 seconds to ensure all changes take effect..."
echo "Press Ctrl+C to cancel reboot"
sleep 10

print_status "Rebooting now..."
reboot 