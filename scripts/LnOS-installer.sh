#!/bin/bash

# /*
# Copyright 2025 UTA-LugNuts Authors.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# */


#
# @file LnOS-installer.sh
# @brief Installs Arch linux and 
# @author Betim-Hodza, Ric3y
# @date 2025
#

set -e

# Prechecks for users that are cloning the install script to run in the archinstaller iso and not the lnos iso
# the package paths are different on clones
if cat /root/LnOS/pacman_packages/CSE_packages.txt | grep git -q ; then
    echo "Detected cloned install, setting cloned to 1"
    CLONED=1
else
CLONED=0
fi

if ! command -v gum &> /dev/null; then
    echo "Installing gum..."
    pacman -Sy --noconfirm gum
fi

if ! command -v nmtui &> /dev/null; then
    echo "Installing network manager..."
    pacman -Sy --noconfirm networkmanager
    NetworkManager
fi

# logging functions (only for 1 line)
gum_echo()
{
    gum style --border normal --margin "1 2" --padding "2 4" --border-foreground 130 "$@"
}
gum_error()
{
    gum style --border double --margin "1 2" --padding "2 4" --border-foreground 1 "$@"
}
gum_complete()
{
    gum style --border normal --margin "1 2" --padding "2 4" --border-foreground 158 "$@"
}

# Make user connect to internet
# make it a bit simpler and just force nmtui on them
echo "Please connect to the internet"

gum_echo "connect to the internet? (installer wont work without it)"
gum confirm || exit

nmtui


# Combines part 2 into part 1 script as to make installation easier
# sets up the desktop environment and packages
setup_desktop_and_packages()
{
    local username="$1" # Pass username as parameter

    gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Hello, there. Welcome to LnOs auto setup script"

    # Install essential packages 
  	gum spin --spinner dot --title "Installing developer tools needed for packages" -- pacman -S --noconfirm base-devel git wget networkmanager btrfs-progs openssh git dhcpcd networkmanager vi vim iw netcl wget curl xdg-user-dirs
    
    # Enable network services
    systemctl enable dhcpcd
    systemctl enable NetworkManager

    # Desktop Environment Installation
    while true; do
		DE_CHOICE=$(gum choose --header "Choose your Desktop Environment (DE):" \
            "Gnome(good for beginners, similar to mac)" \
            "KDE(good for beginners, similar to windows)" \
            "Hyprland(Tiling WM, basic dotfiles but requires more DIY)" \
            "DWM(similar to Hyprland)" \
            "TTY (no install required)")
            
		if [[ "$DE_CHOICE" == "TTY (no install required)" ]]; then
			echo "TTY is preinstalled !"
            break
        fi
        
        gum confirm "You selected: $DE_CHOICE. Proceed with installation?" && break
        gum_echo "Returning to selection menu..."
    done

    case "$DE_CHOICE" in
        "Gnome(good for beginners, similar to mac)")
            gum_echo "Installing Gnome..."
            pacman -S --noconfirm xorg xorg-server gnome gdm
            systemctl enable gdm.service
            ;;
				"KDE(good for beginners, similar to windows)")
            gum_echo "Installing KDE..."
            pacman -S --noconfirm xorg xorg-server plasma kde-applications sddm
            systemctl enable sddm.service
            ;;
        "Hyprland(Tiling WM, basic dotfiles but requires more DIY)")
            gum_echo "Installing Hyprland..."
            pacman -S --noconfirm wayland hyprland noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra kitty networkmanager

            # call and run JaKooLit's arch hyprland install
            gum_echo "Downloading JaKooLit's hyprland, please run the script after installation!"
            sleep 2
            wget https://raw.githubusercontent.com/JaKooLit/Arch-Hyprland/main/auto-install.sh
        
            ;;
		"DWM(similar to Hyprland)")
            gum_echo "Installing DWM..."
			gum_echo "[WARNING] DWM requires more work in the future, for now this option doesn't do anything"
            #pacman -S --noconfirm uwsm
            #systemctl enable lightdm.service
            ;;
    esac

    # Package Installation
    while true; do
        THEME=$(gum choose --header "Choose your installation Profile:" "CSE" "Custom")
        gum confirm "You selected: $THEME. Proceed with installation?" && break
    done

    case "$THEME" in
        "CSE")
            # ensure we have the right packages
            PACMAN_PACKAGES=$(cat /root/LnOS/pacman_packages/CSE_packages.txt)
            if [ ! -f "/root/LnOS/pacman_packages/CSE_packages.txt" ]; then
                gum_error  "Error: CSE_packages.txt not found in /root/LnOS/pacman_packages/. ."
            else
                # checking if cloned
                if CLONED ; then
                    PACMAN_PACKAGES=$(cat /root/LnOS/scripts/pacman_packages/CSE_packages.txt)
                else
                    gum_error "Error: CSE_packages.txt not found in /root/LnOS/scripts/pacman_packages/."
                    exit 1
                fi
            fi
			# Choose packages from CSE list (PACMAN)
            PACMAN_PACKAGES=$(cat /root/LnOS/pacman_packages/CSE_packages.txt)
            gum spin --spinner dot --title "Installing pacman packages..." -- pacman -S --noconfirm "$PACMAN_PACKAGES" 

            # AUR will most likely be short with a few packages
            # webcord, brave are the big ones that come to mind
            # the reason is id like to teach users how to properly use aur
            gum style \
                --foreground 255 --border-foreground 130 --border double \
                --width 100 --margin "1 2" --padding "2 4" \
                'AUR (arch user repository) is less secure because its not maintained by arch.' \
                'LnOS Maintainers picked these packages cause their released were signed with PGP keys' \
            gum confirm "Will you proceed to download AUR packages ? (i.e. brave, webcord)" || return
            
            # clone paru and build
            git clone https://aur.archlinux.org/paru.git
            cd paru
            makepkg -si
            # exit and clean up paru
            cd ..
            rm -rf paru


            gum_echo "Please review the packages you're about to download"
            # check if we have the right packages
            PARU_PACKAGES=$(cat /root/LnOS/paru_packages/paru_packages.txt)
            if [ ! -f "/root/LnOS/paru_packages/paru_packages.txt" ]; then
                gum_error  "Error: CSE_packages.txt not found in /root/LnOS/paru_packages/. ."
            else
                # checking if cloned
                if CLONED ; then
                    PARU_PACKAGES=$(cat /root/LnOS/scripts/paru_packages/paru_packages.txt)
                else
                    gum_error "Error: CSE_packages.txt not found in /root/LnOS/scripts/paru_packages/."
                    exit 1
                fi
            fi
            paru -S "$PARU_PACKAGES"


            ;;
        "Custom")
            PACMAN_PACKAGES=$(gum input --header "Enter the pacman packages you want (space-separated):")
            if [ -n "$PACMAN_PACKAGES" ]; then
                gum spin --spinner dot --title "Installing pacman packages..." -- pacman -S --noconfirm "$PACMAN_PACKAGES"
            fi

            gum_echo "AUR (arch user repository) is less secure because it's not maintained by arch. LnOS Maintainers picked these packages cause their released were signed with PGP keys"
            gum confirm "Will you proceed to download AUR packages ? (i.e. brave, webcord)" || return
            
            # clone paru and build
            git clone https://aur.archlinux.org/paru.git
            cd paru
            makepkg -si
            # exit and clean up paru
            cd ..
            rm -rf paru


            gum_echo "Please enter and review the packages you're about to download"
            PARU_PACKAGES=$(gum input --header "Enter the paru packages you want (space-seperated):")
            if [ -n "$PARU_PACKAGES" ]; then
                paru -S "$PARU_PACKAGES"
            fi
            
            ;;
    esac

    # make basic user directories
    cd ~
    mkdir Downloads Pictures Videos Music Documents Public Desktop
    chown "$username:$username" Downloads Pictures Videos Music Documents Public Desktop 
}

# Function to configure the system (common for both architectures)
configure_system()
{
    # install gum again for pretty format
    pacman -Sy --noconfirm gum

    # Set timezone
    ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
    hwclock --systohc

    # Set locale
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

    # Set hostname
    echo "LnOs" > /etc/hostname

    # Set hosts file
    echo "127.0.0.1 localhost" > /etc/hosts
    echo "::1 localhost" >> /etc/hosts

    # Add DNS servers
    echo "nameserver 1.1.1.1" > /etc/resolv.conf # Cloudflare

    # Set root password
    while true; do
        rtpass=$(gum input --password --placeholder="Enter root password: ")
        rtpass_verify=$(gum input --password --placeholder="Enter root password again: ")
        if [ "$rtpass" = "$rtpass_verify" ]; then
            echo "root:$rtpass" | chpasswd
            break
        else
            gum confirm "Passwords do not match. Try again?" || exit 1
        fi
    done

    # Create normal user
    while true; do
        username=$(gum input --prompt "Enter username: ")
        if [ -z "$username" ]; then
            gum_error "Error: Username cannot be empty."
        else
            break
        fi
    done

		# set groups to user
    useradd -m -G audio,video,input,wheel,sys,log,rfkill,lp,adm -s /bin/bash "$username"

		# Get users password
    while true; do
        uspass=$(gum input --password --placeholder="Enter password for $username: ")
        uspass_verify=$(gum input --password --placeholder="Enter password for $username again: ")
        if [ "$uspass" = "$uspass_verify" ]; then
            echo "$username:$uspass" | chpasswd
            break
        else
            gum confirm "Passwords do not match. Try again?" || exit 1
        fi
    done

    # Configure sudoers for wheel group
    pacman -S --noconfirm sudo
    echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel
    chmod 440 /etc/sudoers.d/10-wheel

    # Update 
    pacman -Syu --noconfirm

    
    # setup the desktop environment
    setup_desktop_and_packages "$username"

	gum_echo "LnOS Basic DE / Package install completed!"

    exit 0
}

# Prompts the user and parititions the users selected disk from what we can find
# This makes 2-3 parititions: BOOT, SWAP (if < 15GB ram), BTRFS Linux filesystem
# * Automatically detects UEFI or BIOS, this will mount the parititions as well
setup_drive()
{
    # Prompt user to select a disk
    DISK_SELECTION=$(lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E 'disk' | grep -E 'nvme|sd[a-z]|mmcblk[0-9]' | gum choose --header "Select the disk to install on (or Ctrl-C to exit):")
    DISK="/dev/$(echo "$DISK_SELECTION" | awk '{print $1}')"

    if [ -z "$DISK" ]; then
        gum style --border normal --margin "1" --padding "1" --border-foreground 1 "Error: No disk selected."
        exit 1
    fi

    # Confirm disk selection
    if ! gum confirm "WARNING: This will erase all data on $DISK. Continue?"; then
        exit 1
    fi

    # check what type of drive
    if grep -q "nvme" <<< "$DISK"; then
        NVME=1
    else
        NVME=0
    fi   

    # Detect UEFI or BIOS
    if [ -d /sys/firmware/efi ]; then
        UEFI=1
    else
        UEFI=0
    fi

    # Check RAM and decide swap size
    RAM_GB=$(awk '/MemTotal/ {print int($2 / 1024 / 1024)}' /proc/meminfo)
    if [ "$RAM_GB" -lt 15 ]; then
        SWAP_SIZE=4096  # 4 GiB
        gum_echo "System has ${RAM_GB}GB RAM. Creating 4 GiB swap partition"
    else
        SWAP_SIZE=0
        gum_echo "System has ${RAM_GB}GB RAM."
    fi

    # Partition the disk UEFI and DOS compatible
    if [ $UEFI -eq 1 ]; then
        parted "$DISK" mklabel gpt
        parted "$DISK" mkpart ESP fat32 1MiB 513MiB
        parted "$DISK" set 1 esp on        
        if [ $SWAP_SIZE -gt 0 ]; then
            parted "$DISK" mkpart swap linux-swap 513MiB $((513 + SWAP_SIZE))MiB
            parted "$DISK" mkpart root btrfs $((513 + SWAP_SIZE))MiB 100%
            SWAP_PART=2
            ROOT_PART=3
        else
            parted "$DISK" mkpart root btrfs 513MiB 100%
            ROOT_PART=2
        fi
        BOOT_PART=1
    else
        parted "$DISK" mklabel msdos
        if [ $SWAP_SIZE -gt 0 ]; then
            parted "$DISK" mkpart primary linux-swap 1MiB ${SWAP_SIZE}MiB
            parted "$DISK" mkpart primary btrfs ${SWAP_SIZE}MiB 100%
            parted "$DISK" set 2 boot on
            SWAP_PART=1
            ROOT_PART=2
        else
            parted "$DISK" mkpart primary btrfs 1MiB 100%
            parted "$DISK" set 1 boot on
            ROOT_PART=1
        fi
    fi

    # Format partitions 
    if [ $UEFI -eq 1 ]; then
        # account for NVME drives seperating paritions with p
        if [ $NVME -eq 1 ]; then
            mkfs.fat -F32 "${DISK}p${BOOT_PART}"  
        else
            mkfs.fat -F32 "${DISK}${BOOT_PART}"
        fi
    fi
    if [ $SWAP_SIZE -gt 0 ]; then
        # account for NVME 
        if [ $NVME -eq 1 ]; then
            mkswap "${DISK}p${SWAP_PART}" 
        else
            mkswap "${DISK}${SWAP_PART}" 
        fi
    fi
    
    if [ $NVME -eq 1 ];then
        mkfs.btrfs -f "${DISK}p${ROOT_PART}"  
    else
        mkfs.btrfs -f "${DISK}${ROOT_PART}"  
    fi

    # Mount partitions
    if [ $NVME -eq 1 ]; then
        mount "${DISK}p${ROOT_PART}" /mnt
    else
        mount "${DISK}${ROOT_PART}" /mnt
    fi

    if [ $UEFI -eq 1 ]; then
        if [ $NVME -eq 1 ]; then
            mkdir /mnt/boot
            mount "${DISK}p${BOOT_PART}" /mnt/boot
        else
            mkdir /mnt/boot
            mount "${DISK}${BOOT_PART}" /mnt/boot
        fi
    fi
}

# Copies the repo's files into the chroot, this is for it to be permenant on reboot
copy_lnos_files()
{
	LNOS_REPO="/root/LnOS"
	if [ ! -d "$LNOS_REPO" ]; then
		gum style --border normal --margin "1" --padding "1" --border-foreground 1 "Error: LnOS repository not found at $LNOS_REPO. Please clone it before running the installer."
		exit 1
	fi
	mkdir -p /mnt/root/LnOS
	cp -r "$LNOS_REPO/scripts/pacman_packages" /mnt/root/LnOS/
	cp "$LNOS_REPO/scripts/LnOS-auto-setup.sh" /mnt/root/LnOS/ 2>/dev/null || true # Optional, ignore if not present
	# Optionally copy documentation files
	cp -r "$LNOS_REPO/docs" /mnt/root/LnOS/ 2>/dev/null || true
	cp "$LNOS_REPO/README.md" "$LNOS_REPO/LICENSE" "$LNOS_REPO/AUTHORS" "$LNOS_REPO/SUMMARY.md" "$LNOS_REPO/TODO.md" /mnt/root/LnOS/ 2>/dev/null || true

}

# Function to install on x86_64 (runs from Arch live ISO)
install_x86_64()
{
	# prompt and paritition the drives
	setup_drive

    # Install base system (zen kernel may be cool, but after some research about hardening, the linux hardened kernel makes 10x more sense for students and will be the default)
    gum_echo "Installing base system, will take some time (grab a coffee)"
    pacstrap /mnt base linux-hardened linux-firmware btrfs-progs

    gum_echo "base system install done!"

	# Copy LnOS repository files to target system (in order for the spin to happen you have to startup a new bash instance)
	gum spin --spinner dot --title "copying LnOS files" -- bash -c "$(declare -f copy_lnos_files); copy_lnos_files"

    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab

	# Chroot and configure the OS,
	# before we enter chroot we also need to declare
	# these bash functions as well so they can run
    arch-chroot /mnt /bin/bash -c "$(declare -f configure_system setup_desktop_and_packages gum_echo gum_error gum_complete); configure_system"

    # Cleanup and Install GRUB
    if [ $UEFI -eq 1 ]; then
        arch-chroot /mnt pacman -S --noconfirm grub efibootmgr
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    else
        arch-chroot /mnt pacman -S --noconfirm grub
        arch-chroot /mnt grub-install --target=i386-pc $DISK
    fi
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

    # Unmount and reboot
    umount -R /mnt
    gum_complete "Installation complete. Rebooting in 10 seconds..."
		sleep 10
    reboot
}

# Function to prepare ARM SD card (for Raspberry Pi, run from existing Linux system)
prepare_arm()
{
    # Prompt for SD card device using GUM
    gum style --border normal --margin "1" --padding "1" --border-foreground 212 "Available disks:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    DISK=$(lsblk -d -o NAME | grep -E 'sd[a-z]|mmcblk[0-9]' | gum choose --header "Select the SD card device to prepare (e.g., /dev/mmcblk0):" | sed 's|^|/dev/|')

    if [ -z "$DISK" ]; then
        gum style --border normal --margin "1" --padding "1" --border-foreground 1 "Error: No disk selected."
        exit 1
    fi

    # Confirm disk selection
    if ! gum confirm "WARNING: This will erase all data on $DISK. Continue?"; then
        exit 1
    fi

    # Partition the SD card
    parted "$DISK" mklabel msdos
    parted "$DISK" mkpart primary fat32 1MiB 257MiB
    parted "$DISK" mkpart primary btrfs 257MiB 100%

    # Format partitions
    mkfs.fat -F32 "${DISK}p1"
    mkfs.btrfs "${DISK}p2"

    # Mount partitions
    mount "${DISK}p2" /mnt
    mkdir /mnt/boot
    mount "${DISK}p1" /mnt/boot

    # Download and extract Arch Linux ARM tarball (Raspberry Pi 4 example)
    wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-4-ext4-root.tar.gz -O /tmp/archlinuxarm.tar.gz
    tar -xzf /tmp/archlinuxarm.tar.gz -C /mnt

    # Copy LnOS repository files to target system
    LNOS_REPO="/root/LnOS"
    if [ ! -d "$LNOS_REPO" ]; then
        gum style --border normal --margin "1" --padding "1" --border-foreground 1 "Error: LnOS repository not found at $LNOS_REPO. Please clone it before running the installer."
        exit 1
    fi
    mkdir -p /mnt/root/LnOS
    cp -r "$LNOS_REPO/scripts/pacman_packages" /mnt/root/LnOS/
    cp "$LNOS_REPO/scripts/LnOS-auto-setup.sh" /mnt/root/LnOS/ 2>/dev/null || true # Optional, ignore if not present
    # Optionally copy documentation files
    cp -r "$LNOS_REPO/docs" /mnt/root/LnOS/ 2>/dev/null || true
    cp "$LNOS_REPO/README.md" "$LNOS_REPO/LICENSE" "$LNOS_REPO/AUTHORS" "$LNOS_REPO/SUMMARY.md" "$LNOS_REPO/TODO.md" /mnt/root/LnOS/ 2>/dev/null || true

    gum style --border normal --margin "1" --padding "1" --border-foreground 212 "Copied LnOS repository files to /mnt/root/LnOS"

    # Install qemu-user-static if not present
    if ! command -v qemu-arm-static &> /dev/null; then
        pacman -S --noconfirm qemu-user-static
    fi

    # Chroot and configure
    arch-chroot /mnt /bin/bash -c "$(declare -f configure_system setup_desktop_and_packages); configure_system"

    # Unmount
    umount -R /mnt
    gum style --border normal --margin "1" --padding "1" --border-foreground 212 "SD card preparation complete. Insert into Raspberry Pi and boot."
}

# Main logic
if [ "$1" = "--target=x86_64" ]; then
  install_x86_64
elif [ "$1" = "--target=aarch64" ]; then
  gum_error "WIP: Please come back later!"
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then

	gum style \
		--foreground 255 --border-foreground 130 --border double \
		--width 100 --margin "1 2" --padding "2 4" \
		'Help Menu:' \
		'Usage: installer.sh --target=[x86_64 | aarch64] or -h' \
		'[--target]: sets the installer"s target architecture (for the cpu)' \
		'Please check your cpu architecture by running: uname -m ' \
		'[-h] or [--help]: Brings up this help menu'

	exit 0
else
	gum style \
		--foreground 255 --border-foreground 1 --border double \
		--width 100 --margin "1 2" --padding "2 4" \
		'Usage: installer.sh --target=[x86_64 | aarch64] or -h' \
		'[--target]: sets the installer"s target architecture (for the cpu)' \
		'Please check your cpu architecture by running: uname -m ' \
		'[-h] or [--help]: Brings up this help menu'
	exit 1
fi
