# Testing

For testing this is the process I follow

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
