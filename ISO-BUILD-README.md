# LnOS Custom Arch Linux ISO Build Guide

This guide explains how to build and use the custom LnOS Arch Linux ISO.

## Prerequisites

### For Local Building
- Arch Linux system (or Arch-based container)
- `archiso` package installed: `sudo pacman -S archiso`
- Root privileges for ISO building
- At least 4GB free space

### For GitHub Actions
- Repository with GitHub Actions enabled
- Workflows will automatically build on push to main or manual trigger

## Build Instructions

### Local Build
```bash
# Clone the repository
git clone https://github.com/uta-lug-nuts/LnOS.git
cd LnOS

# Build x86_64 ISO
./build-iso.sh x86_64

# Build aarch64 ISO  
./build-iso.sh aarch64

# Output will be in ./out/ directory
```

### GitHub Actions Build
1. Push changes to main branch, or
2. Go to Actions tab → "Build LnOS ISO" → "Run workflow"
3. Select architecture (x86_64, aarch64, or both)
4. Download artifacts from the workflow run

## Project Structure

```
LnOS/
├── archiso/                    # ISO build configuration
│   ├── airootfs/              # Files to include in live system
│   │   ├── root/              # Root user files
│   │   └── usr/               # System binaries and data
│   ├── efiboot/               # UEFI boot configuration
│   ├── syslinux/              # BIOS boot configuration
│   ├── packages.x86_64        # Packages for x86_64
│   ├── packages.aarch64       # Packages for aarch64
│   ├── pacman.conf           # Pacman configuration
│   └── profiledef.sh         # ISO build profile
├── scripts/                   # LnOS installer scripts
│   ├── LnOS-installer.sh     # Main installer
│   └── pacman_packages/      # Package lists
├── build-iso.sh              # Local build script
└── .github/workflows/        # GitHub Actions workflows
```

## Usage Instructions

### 1. Write ISO to USB
```bash
# Replace /dev/sdX with your USB device
sudo dd if=out/lnos-*.iso of=/dev/sdX bs=4M status=progress sync
```

### 2. Boot from USB
- Boot your target system from the USB drive
- The system will automatically log in as root
- Network should be configured automatically

### 3. Run the Installer
```bash
# Navigate to installer directory
cd /root/LnOS/scripts

# Run installer for x86_64
./LnOS-installer.sh --target=x86_64

# Run installer for aarch64 (when supported)
./LnOS-installer.sh --target=aarch64

# Show help
./LnOS-installer.sh --help
```

## Installer Features

### Interactive Disk Selection
- Lists available storage devices
- Confirms selection before partitioning
- Supports both UEFI and BIOS systems
- Automatic swap partition for systems <15GB RAM

### Desktop Environment Options
- **GNOME**: Beginner-friendly, macOS-like
- **KDE**: Beginner-friendly, Windows-like  
- **Hyprland**: Tiling window manager
- **DWM**: Minimal tiling window manager
- **TTY**: No GUI (terminal only)

### Package Installation Profiles
- **CSE**: Computer Science/Engineering focused packages
- **Custom**: Manual package selection

### Automatic Configuration
- User account creation with sudo access
- Network configuration (NetworkManager + dhcpcd)
- Bootloader installation (GRUB)
- System locale and timezone setup

## Customization

### Adding Packages
Edit the appropriate file:
- `archiso/packages.x86_64` for x86_64 live environment
- `archiso/packages.aarch64` for aarch64 live environment
- `scripts/pacman_packages/*.txt` for installation profiles

### Modifying Boot Configuration
- UEFI: Edit files in `archiso/efiboot/`
- BIOS: Edit files in `archiso/syslinux/`

### Custom Scripts
Add scripts to `archiso/airootfs/usr/local/bin/` and they'll be available in the live environment.

## Troubleshooting

### Build Issues
- Ensure archiso is up to date: `sudo pacman -Syu archiso`
- Check available disk space (need 4GB+)
- Verify all scripts have execute permissions

### Boot Issues
- Try different USB creation method (Ventoy, Rufus, etc.)
- Check UEFI/BIOS settings (disable Secure Boot if needed)
- Verify ISO checksum

### Installation Issues
- Check network connectivity: `ping 8.8.8.8`
- Verify disk permissions and space
- Check logs in `/var/log/`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes with local build
4. Submit pull request
5. GitHub Actions will test your changes

## Architecture Support

- **x86_64**: Full support, tested
- **aarch64**: Basic support, work in progress
- **i686**: Not supported

## License

Licensed under the Apache License, Version 2.0. See LICENSE file for details.