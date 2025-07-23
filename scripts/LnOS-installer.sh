#!/bin/bash
set -e

# Function to configure the system (common for both architectures)
configure_system() {
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
		rtpass="0"
		rtpass_verify="1"
		while [[ $rtpass != $rtpass_verify ]]; do
			echo "Enter Root password: "
			read rtpass
			echo "enter root pass again: "
			read rtpass_verify
		done
    echo "root:$rtpass" | chpasswd

		# create normal user
		uspass="0"
		uspass_verify="1"
		username="empty"
		
		echo "Enter username:"
		read username	
		useradd -m -G audio,video,input,wheel,sys,log,rfkill,lp,adm -s /bin/bash $username

		while [[ $uspass != $uspass_verify ]]; do
			echo "Enter $username password: "
			read uspass
			echo "Enter $username password again: "
			read uspass_verify
		done
		echo "bay:$uspass" | chpasswd

		# essential packages moving forward
    pacman -Syu --noconfirm
    pacman -S --noconfirm btrfs-progs sudo

    # Install additional tools (optional customization)
    pacman -S --noconfirm vim neovim git kitty

		echo "Basic Arch Install done!"
		echo "Please reboot and run part 2 (LnOs-auto-setup)"
		echo "To setup LnOs Desktop Environment and applications"

		sleep 1 
		exit 0
}

# Function to install on x86_64 (runs from Arch live ISO)
install_x86_64() {
    # Prompt for disk
    echo "Available disks:"
    lsblk
	
		# Initialize DISK as empty
		DISK=""

		# Prompt for disk until a valid block device is provided
		while true; do
				# Display available disks to guide the user
				echo "Available disks:"
				lsblk -d -o NAME,SIZE,TYPE | grep disk
				echo "Enter the disk to install on (e.g., /dev/sda, or press Ctrl+C to exit):"
				read -r DISK

				# Ensure DISK is not empty
				if [[ -z "$DISK" ]]; then
						echo "Error: No disk specified. Please enter a valid disk."
						continue
				fi

				# Check if DISK is a valid block device
				if lsblk "$DISK" >/dev/null 2>&1; then
						echo "Valid block device: $DISK"
						break
				else
						echo "Error: $DISK does not exist or is not a valid block device."
						echo "Please enter a valid disk (e.g., /dev/sda)."
				fi
		done


		
    echo "WARNING: This will erase all data on $DISK. Continue? (y/n)"
    read CONFIRM
    if [ "$CONFIRM" != "y" ]; then
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
        echo "System has ${RAM_GB} GB RAM. Creating 4 GiB swap partition."
    else
        SWAP_SIZE=0
        echo "System has ${RAM_GB} GB RAM. No swap partition will be created."
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
    mkfs.btrfs ${DISK}${ROOT_PART}

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
    # Prompt for SD card device
    echo "Available disks:"
    lsblk
    echo "Enter the SD card device to prepare (e.g., /dev/mmcblk0):"
    read DISK
    echo "WARNING: This will erase all data on $DISK. Continue? (y/n)"
    read CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        exit 1
    fi

    # Partition the SD card
    parted $DISK mklabel msdos
    parted $DISK mkpart primary fat32 1MiB 513MiB
    parted $DISK mkpart primary btrfs 513MiB 100%

    # Format partitions
    mkfs.fat -F32 ${DISK}p1
    mkfs.btrfs ${DISK}p2

    # Mount partitions
    mount ${DISK}p2 /mnt
    mkdir /mnt/boot
    mount ${DISK}p1 /mnt/boot

    # Download and extract Arch Linux ARM tarball (Raspberry Pi 4 example)
    wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-4-ext4-root.tar.gz -O /tmp/archlinuxarm.tar.gz
    tar -xzf /tmp/archlinuxarm.tar.gz -C /mnt

    # Install qemu-user-static if not present (for chroot on x86_64 host)
    if ! command -v qemu-arm-static &> /dev/null; then
        pacman -S --noconfirm qemu-user-static
    fi

    # Chroot and configure
    arch-chroot /mnt /bin/bash -c "$(declare -f configure_system); configure_system"

    # Unmount
    umount -R /mnt
    echo "SD card preparation complete. Insert into Raspberry Pi and boot."
}

# Main logic
if [ "$1" = "--target=x86_64" ]; then
    install_x86_64
elif [ "$1" = "--target=arm" ]; then
    prepare_arm
else
    echo "Usage: $0 --target=[x86_64 | arm]"
    exit 1
fi
