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

>**NOTE:**  
>This is highly experimental and not recommend to try on your dedicated machine yet since it hasn't been thoughrougly tested.
>please instead follow a real install guide from: [[https://wiki.archlinux.org/title/Installation_guide]] 

1. Download Arch Linux ISO:

Get the latest ISO from [[https://archlinux.org/download/]]

2. Create Bootable Media:

Use tools like [rufus](https://rufus.ie/en/) or [Balena Etcher](https://www.balena.io/etcher) to write the ISO to a USB drive or SD card.


3. Boot and Install Base System:

clone our repo:
```bash
git clone https://github.com/uta-lug-nuts/LnOS.git
```

run and choose the target based on cpu architecture:
```bash
./scripts/LnOS-installer.sh --target=[x86_64 | arm]
```

4. Add CS Tools:

After booting into the base system, clone our repo again:
```bash
git clone https://github.com/uta-lug-nuts/LnOS.git
```

run and follow the instructions in:
```bash
./scripts/Environment-setup.sh
```

Done! 



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
* No testing done for ARM.
* no iso specific to the repo 
* No GH Action pipeline test 


## Credits

Inspired by Professor Bakker’s and UTA LUGNUTS Community of a vision for a UTA-specific distro.

Built on the amazing work of the Arch Linux community.
Install Files look beautiful from the wonderful tool: [GUM](https://github.com/charmbracelet/gum?tab=readme-ov-file)
