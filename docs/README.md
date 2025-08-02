<center><img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Tux_with_toolbox.png?raw=true" width=50% alt="tux with toolbox"></center>

# LnOS a Customized Arch Distro tailored to UTA Students
"A UTA flavored distro with all the applications and tools the different engineering majors use" - Professor Bakker

## Overview
The-LN-Project is a custom Linux distribution based on Arch Linux, designed specifically for University of Texas at Arlington (UTA) students. It aims to provide a lightweight, flexible, and powerful environment tailored to the needs of engineering students.The distro supports both x86_64 and ARM architectures (e.g., Raspberry Pi), ensuring compatibility with a wide range of student hardware.

* First focused discipline is Computer Science (CS). 

## Goals 

* Lightweight and minimal base, built from Arch Linux.
* Pre-configured tools for CS students, with plans to expand to other engineering disciplines (e.g., EE).
* Easy installation process for students new to Linux.
* Rolling updates to keep software current. (tool to update easily TUI)
* Easy to read Documentation source not only for LnOS but for any configurable tool thats on Arch Linux

## Want to request a feature or report a bug, open an Issue!
* [Github issues](https://github.com/uta-lug-nuts/LnOS/issues)

## How to Contribute
We welcome contributions from UTA students, faculty and the FOSS Community!

### Report Issues: Use GitHub Issues to report bugs or suggest features.
* [Create a Issue](https://github.com/uta-lug-nuts/LnOS/issues/new/choose)


### Testing / Developers Guide

Click here to see guide on testing: [Testing](testing.md)
(helpful when contributing)

## Features

* **Target Architectures:** x86_64 and (aarch64 / aarch32) 
  * Arm we're still researching (v7 or v8)
* **Base System:** Minimal Arch Linux with a rolling release model.
* **Major Themed presets:** Engineers will have preset options to choose  
* **Desktop Environment:** [Gnome](https://www.gnome.org/)(similar to macos) [KDE](https://kde.org/)(similar to windows) and Tiling Window Managers like [Hyprland](https://hypr.land/), and [DWM](https://dwm.suckless.org/).
  * To learn more about Tiling Window Managers [click here](tilingWM.md)
* Documentation: Guides and support for UTA students on installation and customization of tools.


## Installation Instructions

### Custom ISO Installation

Pre-built LnOS ISOs are available with the installer included.

#### Option 1: Download Pre-built ISO
1. Download the latest release from [GitHub Releases](https://github.com/uta-lug-nuts/LnOS/releases)
   - `lnos-x86_64-*.iso` for Intel/AMD 64-bit systems
   - `lnos-aarch64-*.iso` for ARM 64-bit systems (Raspberry Pi 4+)

2. Create bootable USB:
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

### Development Environment

To contribute to LnOS, use the VS Code dev container:

1. Install VS Code with "Dev Containers" extension
2. Clone repository: `git clone https://github.com/uta-lug-nuts/LnOS.git`
3. Open in VS Code: `code LnOS`
4. Reopen in container: `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"

The dev container includes:
- Arch Linux environment
- Pre-installed archiso and build tools
- Build aliases: `build-x86`, `build-arm`, `clean-build`
- Shell script linting and formatting
- Cross-platform compatibility (Windows, macOS, Linux)

### Manual Installation

1. Download Arch Linux ISO from [archlinux.org/download](https://archlinux.org/download/)

2. Create bootable media using [Rufus](https://rufus.ie/en/) or [Balena Etcher](https://www.balena.io/etcher)

3. Boot and install:
   ```bash
   git clone https://github.com/uta-lug-nuts/LnOS.git
   ./LnOS/scripts/LnOS-installer.sh --target=x86_64
   ``` 



## Included Packages (CS Focus)
Here’s a preliminary list of tools for CS students:

* Editors: VSCode (vscode), Vim
* Version Control: Git
* Compilers/Debuggers: GCC, GDB
* Languages: Python, C/C++
* Utilities: Bash, Make, OpenSSH
* Optional: Docker (for containerization), Valgrind (for memory debugging)

More tools will be added based on student feedback.


## Resources We’ve Looked At

[Arch Linux Official Site](https://archlinux.org)
[Linux From Scratch](https://linuxfromscratch.org)
[Arch Linux ARM](https://archlinuxarm.org/)
[Arch linux install guide](https://arch.d3sox.me/installation/setup-users)
[GUM](https://github.com/charmbracelet/gum?tab=readme-ov-file)
* this has seriously been amazing


## Known Issues

* Not fully reliable yet (still not even a 1.0.0 release)
* ARM64 support is work in progress (basic support implemented)
* Limited testing on various hardware configurations
* Some desktop environments may require additional configuration 


## Credits

Inspired by Professor Bakker’s and UTA LUGNUTS Community of a vision for a UTA-specific distro.

Built on the amazing work of the [Arch Linux community](htttps://archlinux.org).
Install Files look beautiful from the wonderful tool: [GUM](https://github.com/charmbracelet/gum?tab=readme-ov-file)
