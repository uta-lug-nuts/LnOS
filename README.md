# The-LN-Project
"A UTA flavored distro with all the applications and tools the different engineering majors use" - Professor Bakker

## Overview
The-LN-Project is a custom Linux distribution based on Arch Linux, designed specifically for University of Texas at Arlington (UTA) students. It aims to provide a lightweight, flexible, and powerful environment tailored to the needs of engineering students.The distro supports both x86_64 and ARM architectures (e.g., Raspberry Pi), ensuring compatibility with a wide range of student hardware.

* First focused discipline is Computer Science (CS). 

## Goals 

* Lightweight and minimal base, built from Arch Linux.
* Pre-configured tools for CS students, with plans to expand to other engineering disciplines (e.g., EE).
* Easy installation process for students new to Linux.
* Rolling updates to keep software current. (tool to update easily TUI)


## Features

* Target Architectures: x86_64 and ARM (Raspberry Pi compatible).
* Base System: Minimal Arch Linux with a rolling release model.
CS Tools: Includes VSCode, Vim, Git, GCC, GDB, Python, and more.
Desktop Environment: Lightweight options like XFCE or i3 (configurable during install).
Documentation: Guides and support for UTA students.


## Installation Instructions
Since Arch Linux requires a manual installation process, we’re working on a custom script to automate setup for The-LN-Project. For now, follow these steps to install a basic version:

1. Download Arch Linux ISO:

Get the latest ISO from archlinux.org.
For ARM, use the Arch Linux ARM image from archlinuxarm.org.


2. Create Bootable Media:

Use tools like rufus or Balena Etcher to write the ISO to a USB drive or SD card.


3. Boot and Install Base System:

Follow the Arch Installation Guide.
Install the minimal base system (base, linux, linux-firmware).


4. Add CS Tools:

After booting into the base system, install key packages:
``` pacman -Syu vim git code gcc gdb python xfce4 hyprland ```


5. Configure a desktop environment (e.g., XFCE or hyprland) or leave it as a minimal CLI setup.


6. Future Automation:

A custom installer script is in development to streamline this process. Stay tuned!




## Included Packages (CS Focus)
Here’s a preliminary list of tools for CS students:

* Editors: VSCode (code), Vim
* Version Control: Git
* Compilers/Debuggers: GCC, GDB
* Languages: Python, C/C++
* Utilities: Bash, Make, OpenSSH
* Optional: Docker (for containerization), Valgrind (for memory debugging)

More tools will be added based on student feedback.

## How to Contribute
We welcome contributions from UTA students and faculty!

Report Issues: Use GitHub Issues to report bugs or suggest features.
Add Tools: Propose packages for CS or other disciplines.
Improve Docs: Help write guides or improve this README.


## Resources We’ve Looked At

Arch Linux Official Site
Linux From Scratch
Arch Linux ARM


## Known Issues

Manual installation is complex for beginners—custom installer in progress.
Limited ARM package testing—needs more validation on Raspberry Pi.


## Credits

Inspired by Professor Bakker’s vision for a UTA-specific distro.
Built on the amazing work of the Arch Linux community.

