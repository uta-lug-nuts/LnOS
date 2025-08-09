# ARM Image Partition Expansion

## Overview

The LnOS ARM image now supports automatic partition expansion to utilize the entire SD card space, regardless of the card's size. This feature ensures that users get maximum storage capacity from their SD cards.

**Two ARM image options are available:**
- **Minimal Image (512MB)**: Small, fast download for LnOS installation
- **Full Image (1.5GB)**: Complete system with automatic expansion

## How It Works

### Image Size Options

#### Minimal Image (512MB)
- **Boot Partition**: 128MB FAT32
- **Root Partition**: ~384MB ext4
- **Purpose**: Fast download, LnOS installation only
- **Use Case**: Network installation, minimal storage requirements

#### Full Image (1.5GB)
- **Boot Partition**: 256MB FAT32
- **Root Partition**: ~1.3GB ext4 (initially)
- **Purpose**: Complete system with automatic expansion
- **Use Case**: Standalone system, maximum storage utilization

### Automatic Expansion
On first boot, the system automatically:
1. Detects the actual SD card size
2. Expands the root partition to use all available space
3. Resizes the filesystem to match the new partition size
4. Reboots to ensure all changes take effect
5. Disables the expansion service to prevent re-running

### Manual Expansion
If automatic expansion doesn't work or you want to expand manually:
```bash
sudo /root/LnOS/scripts/expand-rootfs.sh
```

## Technical Details

### Partition Layout

#### Minimal Image
- **Boot Partition**: 128MB FAT32 (fixed size)
- **Root Partition**: ~384MB (installation only)

#### Full Image
- **Boot Partition**: 256MB FAT32 (fixed size)
- **Root Partition**: Initially ~1.3GB, expands to use remaining space

### Required Tools
The expansion process uses:
- `parted` - for partition resizing
- `resize2fs` - for filesystem resizing (from `e2fsprogs` package)
- `partprobe` - for partition table refresh

### Safety Features
- Expansion only runs once (tracked by flag file)
- Automatic rollback if expansion fails
- Verification of partition and filesystem sizes
- User confirmation for manual expansion

## Usage

### Building the Images
```bash
# Build minimal image (512MB)
sudo ./build-arm-minimal.sh [rpi4|generic]

# Build full image (1.5GB)
sudo ./build-arm-image.sh [rpi4|generic]
```

### Writing to SD Card
```bash
sudo dd if=out/lnos-arm64-rpi4-YYYY.MM.DD.img of=/dev/sdX bs=4M status=progress
```

### First Boot
1. Insert SD card and boot the device
2. The system will automatically expand partitions
3. Wait for reboot to complete
4. The root filesystem will now use the entire SD card space

## Troubleshooting

### Expansion Failed
If automatic expansion fails:
1. Check if `parted` and `resize2fs` are available
2. Run manual expansion script
3. Check system logs for errors

### Manual Expansion Issues
- Ensure you're running as root
- Verify the SD card is properly detected
- Check that the root filesystem is mounted

### Verification
To verify expansion worked:
```bash
df -h /
parted /dev/mmcblk0 unit MiB print
```

## Benefits

1. **Flexible Storage**: Works with any SD card size (8GB, 16GB, 32GB, 64GB, etc.)
2. **Smaller Downloads**: 512MB minimal vs 1.5GB full vs 4GB original
3. **Faster Downloads**: Minimal image under 1GB, no compression needed
4. **GitHub Compatible**: Both images under GitHub's 2GB file size limit
5. **Automatic**: No user intervention required
6. **Safe**: Includes error handling and verification
7. **Manual Option**: Users can expand manually if needed

## Compatibility

- Works with Raspberry Pi 4 and other ARM64 devices
- Compatible with ext4 filesystem
- Requires parted and e2fsprogs packages (included in base image) 