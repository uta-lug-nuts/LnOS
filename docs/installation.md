## Installation Instructions

This is the custom installation instructions for x86_64 and aarch64(more experimental) 

### Custom ISO Installation

Pre-built LnOS ISOs are available with the installer included.

#### Option 1: Download Pre-built ISO

> ⚠️ **SECURITY NOTICE**: Always verify file signatures before use! All LnOS releases are digitally signed.

1. Download the latest release from [GitHub Releases](https://github.com/uta-lug-nuts/LnOS/releases)
   - `lnos-x86_64-*.iso` for Intel/AMD 64-bit systems
   - `lnos-aarch64-*.iso` for ARM 64-bit systems (Raspberry Pi 4+)
   - `*.asc` signature files for verification

2. **Verify digital signature** (recommended):
   ```bash
   # Quick verification (auto-imports key)
   curl -fsSL https://raw.githubusercontent.com/bakkertj/LnOS/main/scripts/verify-signature.sh | bash -s -- lnos-*.iso
   
   # Manual verification
   curl -fsSL https://raw.githubusercontent.com/bakkertj/LnOS/main/keys/lnos-public-key.asc | gpg --import
   gpg --verify lnos-*.iso.asc lnos-*.iso
   ```

3. Create bootable USB:
   ```bash
   # Linux/macOS
   sudo dd if=lnos-x86_64-*.iso of=/dev/sdX bs=4M status=progress
   
   # Windows: Use Rufus or Balena Etcher
   ```

3. Boot and install:
   - Boot from USB (automatic login as root)
   - Run the installer: `cd /root/LnOS/scripts && ./LnOS-installer.sh --target=x86_64`
   - Follow the interactive prompts to select packages and desktop environment

#### Option 2: Build Custom ISO

You can actually clone the repo and build the iso for yourself!

##### Using VS Code Dev Container
1. Install VS Code with "Dev Containers" extension
2. Clone and open: 
   ```bash
   git clone https://github.com/uta-lug-nuts/LnOS.git
   cd LnOS
   code .
   ```
3. Open in container: `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
4. Build ISO: 
   ```bash
   ./build-iso.sh x86_64     # Build x86_64 ISO
   ./build-iso.sh aarch64    # Build ARM64 ISO
   ```

##### Using Local Arch Linux
```bash
# Install archiso
sudo pacman -S archiso

# Clone and build
git clone https://github.com/uta-lug-nuts/LnOS.git
cd LnOS
./build-iso.sh x86_64
```

##### Using Docker
```bash
git clone https://github.com/uta-lug-nuts/LnOS.git
cd LnOS

# Build in Arch container
docker run --rm --privileged \
  -v $(pwd):/workspace \
  -w /workspace \
  archlinux:latest \
  bash -c "
    pacman -Syu --noconfirm
    pacman -S --noconfirm archiso
    ./build-iso.sh x86_64
  "
```


