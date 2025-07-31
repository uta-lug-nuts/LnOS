# Testing

For testing this is the process I follow
There are two main process:

* [Virtualbox](#virtualbox)
* [QEMU / KVM](#qemu--kvm)

# Virtualbox

## 1. Install Virtual Box

you'll want to obtain virtualbox for whichever distro / OS you're on.
You can go here and grab it: [virtualbox](https://www.virtualbox.org/wiki/Downloads)

## 2. Install Arch linux iso installer

You can download the arch linux iso installer here: [Arch iso](https://archlinux.org/download/)

after you have it downloaded we can move onto using virtual box.

## 3. Fork / Clone our Repo

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192747.png?raw=true" alt="LnOS GH" width="50%">

visit our GH here, oh wait you're already here! (or if theres online documentation then [here!](https://github.com/uta-lug-nuts/LnOS?tab=readme-ov-file#))

you can clone the repo by running

```bash
git clone https://github.com/uta-lug-nuts/LnOS.git
```

* *if you plan on contributing please Fork our Repo*

## 4. Launch Virtualbox and Configure your iso

* You should initially see something like this.

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192212.png?raw=true" alt="virtualbox" >

* Next what you'll want to do is click New: <img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192254.png?raw=true" alt="New button">
* from there will be a popup that asks you a few things, you can fill out the information like this:
  <img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192358.png?raw=true" alt="archinstaller">
* Then Click finish.
* From there click on the installer you just made

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192440.png?raw=true" alt="installer">

* then click settings <img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192505.png?raw=true" alt="settings cog">
* From inside settings, click on Shared Folder

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192541.png?raw=true" alt="shared folder">

* click on the little + next to shared folders

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192633.png?raw=true" alt="plus icon">

* You'll get this popup that will ask you for the folder path and name, I recommend you link the Fork or cloned version of LnOS repo to this so that as you make changes to the scripts they stay up to date.

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716192624.png?raw=true" alt="popup 2">

## 5. Running the VM

Simply Click Start and the VM will fire up, you'll want to select install medium:

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716193037.png?raw=true" alt="arch image boot">


> **NOTE**
> Please use this path: '/run/LnOS' for the mount point

Once you're in you can start testing the scripts by running

```bash
cp -r /run/LnOS
./LnOS/scripts/LnOS-installer.sh --target=x86_64
```

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/Pasted%20image%2020250716193209.png?raw=true" alt="logged in">

* Future Testing Documentation will be written here as we go.
* First iteration will be testing on x86_64 first, we'll move to arm later since I doubt many students would utilize it as of now (especially with the project just starting)


# QEMU / KVM

KVM or Kernel Virtual Machines are another method to test LnOS.


## Check that your linux kernel supports KVM 
Arch Linux kernels provide the required kernel modules to support KVM.

One can check if the necessary modules, kvm and either kvm_amd or kvm_intel, are available in the kernel with the following command:
```bash
$ zgrep CONFIG_KVM= /proc/config.gz
```
The module is available only if it is set to either y or m.

If the command returns nothing, the module needs to be loaded manually; see [Kernel modules#Manual module handling](https://wiki.archlinux.org/title/Kernel_modules#Manual_module_handling).

### Check for Virtual Filesystem support

Use the following command inside the virtual machine to check if the VIRTIO modules are available in the kernel:

```bash
$ zgrep VIRTIO /proc/config.gz
```
Then, check if the kernel modules are automatically loaded with the command:
```bash
$ lsmod | grep virtio
```
In case the above commands return nothing, you need to [load the kernel modules manually](https://wiki.archlinux.org/title/Kernel_modules#Manual_module_handling).

## Installing QEMU

Install the `qemu-full` package (or `qemu-base` for the version without GUI and qemu-desktop for the version with only x86_64 emulation by default) 

### Arch install

```bash
sudo pacman -S qemu-full
# or
sudo pacman -S qemu-base
```

### QEMU Varients
We will be following a *Full-system emulation* this means we'll emulate a full system (good for testing)



## Graphical front-ends for QEMU
Unlike other virtualization programs such as VirtualBox and VMware, **QEMU does not provide a GUI to manage virtual machines** (other than the window that appears when running a virtual machine), nor does it provide a way to create persistent virtual machines with saved settings.

All parameters to run a virtual machine must be specified on the command line at every launch, unless you have created a custom script to start your virtual machine(s).

> We'll create a custom script to make it easier for us   
> (it'll be a copy paste)


## Creating a new virtualized system

QEMU provides the `qemu-img` command to create hard disk images. 

Rhe hard disk image can be in a format such as `qcow2` which **only allocates space to the image file when the guest operating system actually writes to those sectors on its virtual hard disk.** 

The image appears as the full size to the guest operating system, even though it may take up only a very small amount of space on the host system.

>> We'll use the qcow2 as to not take up unecessary space  
>> You can choose to do raw if you want it to take up the full space


> **WARNING**  
> If you store the hard disk images on a Btrfs file system, you should consider disabling Copy-on-Write for the directory before creating any images. Can be specified in option nocow for qcow2 format when creating image:
```bash
qemu-img create -f qcow2 LnOS -o nocow=on 15G
```

Let's make a 10-20GB image (up to you!)
```bash
$ qemu-img create -f qcow2 LnOS 15G
```

### Overlay storage images (Save states)

You can create a storage image once (the 'backing' image) and have QEMU keep mutations to this image in an overlay image. This allows you to revert to a previous state of this storage image. 

You could revert by creating a new overlay image at the time you wish to revert, based on the original backing image.

To create an overlay image, issue a command like:
```bash
$ qemu-img create -o backing_file=img1.raw,backing_fmt=raw -f qcow2 img1.cow
```

After that you can run your QEMU virtual machine as usual:
```bash
$ qemu-system-x86_64 img1.cow
```

## Installing the operating system

This is the first time you will need to start the emulator. To install the operating system on the disk image, you must attach both the disk image and the installation media (ISO) to the virtual machine, and have it boot from the installation media.

* What we'll do is download the [arch iso](https://archlinux.org/download/)

Then run this command (input your path to the arch.iso and ISO drive).

```bash
#!/bin/bash
# please note what i have listed here is for my config, your iso, path, -m (ram), drive file may be named differently if you change stuff.
$ qemu-system-x86_64 \
    -cdrom archlinux-2025.07.01-x86_64.iso \
    -boot order=d \
    -drive file=LnOS,format=qcow2 \
    -m 5G \
    -fsdev local,security_model=passthrough,id=fsdev0,path=/home/bay/Developer/LnOS \
    -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare 
```

* You can save this part as a bash script called StartInstaller.sh

### Using the KVM 

When running the above command you should see this pop up:

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/boot_arch.png?raw=true" alt="booted in arch">

* Next it'll fully boot you up here:

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/inside_arch.png?raw=true" alt="in arch">

next you'll need to mount LnOS by running:
```bash
#!/bin/bash
# create mount point
mkdir -p /run/LnOS
# mount shared folder
mount -t 9p -o trans=virtio hostshare /run/LnOS
# verify
ls /run/LnOS
```

You should see this after running those commands:

<img src="https://github.com/uta-lug-nuts/LnOS/blob/main/docs/images/LnOS_shared?raw=true" alt="in arch">

now all that's left is to copy and run the installer:
```bash
cp -r /run/LnOS
./LnOS/scripts/LnOS-installer.sh --target=x86_64
```

## KVM Resources
* https://wiki.archlinux.org/title/KVM
* https://wiki.archlinux.org/title/QEMU