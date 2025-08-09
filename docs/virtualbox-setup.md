# Virtual Box Setup

This is a guide for LnOS's to install Virtualbox.
Because LnOS uses a custom Linux kernel (The linux-hardened) it adds security features.


## Installation steps for Arch Linux hosts
In order to launch VirtualBox virtual machines on your Arch Linux box, follow these installation steps.

### Install the core packages

You'll need some essential packages because we're on the linux-hardened kernel

```bash
# virtualbox host headers (we use dkms cause we're on a custom kernel)
sudo virtualbox-host-dkms
# the vm
sudo pacman -S virtualbox
# linux-hardened kernel headers
sudo pacman -S linux-hardened-headers
```

When either VirtualBox or the kernel is updated, the kernel modules will be automatically recompiled thanks to the DKMS pacman hook.

### Load the VirtualBox kernel modules

**For the modules to be loaded after installation, either reboot or load the modules once manually;** 

### To load the module manually, run:
```bash
sudo modprobe vboxdrv
```

* the list of modules can be found in `/usr/lib/modules-load.d/virtualbox-host-dkms.conf`

If you do not want the VirtualBox modules to be automatically loaded at boot time, you have to mask the default: `/usr/lib/modules-load.d/virtualbox-host-dkms.conf`
* by creating an empty file (or symlink to /dev/null) with the same name in `/etc/modules-load.d/`


## Common issues

### VirtualBox can't enable the AMD-V extension. 
...Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_SVM_IN_USE).

KVM is the kernel virtual machine, when that's enabled it hogs your virtualization for your machine. Essentially you have to pick KVM or Virtualbox. 

> **NOTE**   
> If you use docker or any containerization tools disabling this might mess it up.    
>
> You have been warned

* If you find virtualbox easier (which it is) then here's the fix

#### *The fix*

We just need to disable the kvm_amd module
```bash
sudo rmmod kvm_amd
```