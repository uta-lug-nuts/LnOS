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

## Todo
Click here to see items next to implement [Todo](TODO.md)

## How to Contribute
We welcome contributions from UTA students and faculty!

Report Issues: Use GitHub Issues to report bugs or suggest features.
* please format your issues like so: [Issue Template](issues.md)
Add Tools: Propose packages for CS or other disciplines.
Improve Docs: Help write guides or improve this README.

### Testing

Click here to see guide on testing: [Testing](testing.md)
(helpful when contributing)

## Features

* Target Architectures: x86_64 and ARM (Raspberry Pi compatible).
* Base System: Minimal Arch Linux with a rolling release model.
CS Tools: Includes VSCode, Vim, Git, GCC, GDB, Python, and more.
Desktop Environment: Lightweight options like XFCE or i3 (configurable during install).
Documentation: Guides and support for UTA students.


## Installation Instructions

**NOTE:** This is highly experimental and not recommend to try on your dedicated machine yet since it hasn't been thoughrougly tested.
please instead follow a real install guide from: [[https://wiki.archlinux.org/title/Installation_guide]] 

1. Download Arch Linux ISO:

Get the latest ISO from [[https://archlinux.org/download/]]

2. Create Bootable Media:

Use tools like rufus or Balena Etcher to write the ISO to a USB drive or SD card.


3. Boot and Install Base System:

clone our repo:
```bash
git clone https://github.com/uta-lug-nuts/LnOS.git
```

run:
```bash
./scripts/installer.sh --target=[x86_64 | arm]
```

4. Add CS Tools:

After booting into the base system, clone our repo again:
```bash
git clone https://github.com/uta-lug-nuts/LnOS.git
```

run and follow the instructions in:
```bash
./scripts/LnOS-auto-setup.sh
```

Done! 



## Included Packages (CS Focus)
Here’s a preliminary list of tools for CS students:

* Editors: VSCode (code), Vim
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

* Manual installation is complex for beginners—custom installer in progress.
* No testing done for ARM.
* no iso specific to the repo 


## Credits

Inspired by Professor Bakker’s and UTA LUGNUTS Community of a vision for a UTA-specific distro.
Built on the amazing work of the Arch Linux community.

