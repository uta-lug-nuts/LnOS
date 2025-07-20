#!/bin/bash
set -e

# install tui fronted
pacman -Sy --noconfirm gum

# Function to configure the system (common for both architectures)
configure_system() {
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

    # Set root password 
		while true; do
			rtpass=$(gum input --password --placeholder="Enter root password: ")
			rtpass_verify=$(gum input --password --placeholder="Enter root password again: ")
			if [ "$rtpass" = "$rtpass_verify" ]; then
    		echo "root:$rtpass" | chpasswd
				break
			else
				gum confirm "Passwords do not match. Try again?"
			fi
		done

	
		# Create normal user using GUM
    username=$(gum input --prompt "Enter username: ")
    if [ -z "$username" ]; then
        echo "Error: Username cannot be empty."
        exit 1
    fi
    useradd -m -G audio,video,input,wheel,sys,log,rfkill,lp,adm -s /bin/bash "$username"

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

		# essential packages moving forward
    pacman -Syu --noconfirm
    pacman -S --noconfirm btrfs-progs sudo

    # Install additional tools (optional customization)
    pacman -S --noconfirm vim neovim git kitty

		gum style --border normal --margin "1" --padding "1" --border-foreground 212 "Basic Arch Install done! Please reboot and run part 2 (LnOs-auto-setup) to setup LnOs Desktop Environment and applications."

		sleep 1 
		exit 0
}

# Function to install on x86_64 (runs from Arch live ISO)
install_x86_64() {
    # Prompt for disk
    gum style --border normal --margin "1" --padding "1" --border-foreground 212 "Available disks:"
		lsblk -d -o NAME,SIZE,TYPE | grep disk
		DISK=$(lsblk -d -o NAME | grep -E 'sd[a-z]|nvme[0-9]n[0-9]' | gum choose --header "Select the disk to install on (or Ctrl-C to exit):" | sed 's|^|/dev/|')

		if [ -z "$DISK" ]; then
			gum style --border normal --margin "1" --padding "1" --border-foreground 1 "Error: No disk selected."
			exit 1
		fi

		# confirm disk selection
		if ! gum confirm "WARNING: This will erase all data on $DISK. Continue ?"; then
			exit 1
		fi

    # Detect UEFI or BIOS
    if [ -d /sys/firmware/efi ]; then
        UEFI=1
    else
        UEFI=0
    fi

    # Check RAM and decide swap size
    RAM_GB=$(awk '/MemTotal/ {print int($2 / 1024 / 1024)}' /proc/meminfo)
    if [ $RAM_GB -lt 15 ]; then
        SWAP_SIZE=4096  # 4 GiB
				gum style --border normal --margin "1" --padding "1" --border-foreground 212 "System has ${RAM_GB}. Creating 4 GiB swap partition"
        echo "System has ${RAM_GB} GB RAM. Creating 4 GiB swap partition."
    else
        SWAP_SIZE=0
				gum style --border normal --margin "1" --padding "1" --border-foreground 212 "System has ${RAM_GB}."
    fi

    # Partition the disk UEFI and DOS compatiable
    if [ $UEFI -eq 1 ]; then
        parted $DISK mklabel gpt
        parted $DISK mkpart ESP fat32 1MiB 513MiB
        parted $DISK set 1 esp on
        if [ $SWAP_SIZE -gt 0 ]; then
            parted $DISK mkpart swap linux-swap 513MiB $((513 + SWAP_SIZE))MiB
            parted $DISK mkpart root btrfs $((513 + SWAP_SIZE))MiB 100%
            SWAP_PART=2
            ROOT_PART=3
        else
            parted $DISK mkpart root btrfs 513MiB 100%
            ROOT_PART=2
        fi
        BOOT_PART=1
    else
        parted $DISK mklabel msdos
        if [ $SWAP_SIZE -gt 0 ]; then
            parted $DISK mkpart primary linux-swap 1MiB ${SWAP_SIZE}MiB
            parted $DISK mkpart primary btrfs ${SWAP_SIZE}MiB 100%
            parted $DISK set 2 boot on
            SWAP_PART=1
            ROOT_PART=2
        else
            parted $DISK mkpart primary btrfs 1MiB 100%
            parted $DISK set 1 boot on
            ROOT_PART=1
        fi
    fi

    # Format partitions
    if [ $UEFI -eq 1 ]; then
        mkfs.fat -F32 ${DISK}${BOOT_PART}
    fi
    if [ $SWAP_SIZE -gt 0 ]; then
        mkswap ${DISK}${SWAP_PART}
    fi
    mkfs.btrfs -f ${DISK}${ROOT_PART}

    # Mount partitions
    mount ${DISK}${ROOT_PART} /mnt
    if [ $UEFI -eq 1 ]; then
        mkdir /mnt/boot
        mount ${DISK}${BOOT_PART} /mnt/boot
    fi

		# Install base system (Zen kernel cause its cool)
    pacstrap /mnt base linux-zen linux-firmware btrfs-progs

    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab

    # Chroot and configure
    arch-chroot /mnt /bin/bash -c "$(declare -f configure_system); configure_system"

    # Install GRUB
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
    echo "Installation complete. Rebooting..."
    reboot
}

# Function to prepare ARM SD card (for Raspberry Pi, run from existing Linux system)
prepare_arm() {
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
    parted "$DISK" mkpart primary fat32 1MiB 513MiB
    parted "$DISK" mkpart primary btrfs 513MiB 100%

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

    # Install qemu-user-static if not present
    if ! command -v qemu-arm-static &> /dev/null; then
        pacman -S --noconfirm qemu-user-static
    fi

    # Chroot and configure
    arch-chroot /mnt /bin/bash -c "$(declare -f configure_system); configure_system"

    # Unmount
    umount -R /mnt
    gum style --border normal --margin "1" --padding "1" --border-foreground 212 "SD card preparation complete. Insert into Raspberry Pi and boot."
}

# Main logic
if [ "$1" = "--target=x86_64" ]; then
    install_x86_64
elif [ "$1" = "--target=arm" ]; then
    prepare_arm
else
		gum style --border normal --margin "1" --padding "1" --border-foreground 1 "Usage: $0 --target=[x86_64 | arm]"
    exit 1
fi
