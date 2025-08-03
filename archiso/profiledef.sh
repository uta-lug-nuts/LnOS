#!/usr/bin/env bash

iso_name="lnos"
iso_label="LNOS_$(date +%Y%m)"
iso_publisher="UTA-LugNuts <https://github.com/uta-lug-nuts/LnOS>"
iso_application="LnOS Install CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
esp_size_mb="128"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xdict-size' '75%' '-b' '1M')
file_permissions=(
  ["/root"]="0:0:750"
  ["/root/.bashrc"]="0:0:644"
  ["/etc/bash.bashrc"]="0:0:644"
  ["/usr/local/bin/LnOS-installer.sh"]="0:0:755"
  ["/usr/local/bin/lnos-autostart.sh"]="0:0:755"
  ["/usr/local/bin/setup-lnos-autostart.sh"]="0:0:755"
  ["/usr/local/bin/lnos-boot-start.sh"]="0:0:755"
  ["/etc/systemd/system/lnos-autostart.service"]="0:0:644"
  ["/etc/systemd/system/lnos-boot.service"]="0:0:644"
  ["/.discinfo"]="0:0:644"
  ["/etc/os-release"]="0:0:644"
  ["/autorun.inf"]="0:0:644"
  ["/README.txt"]="0:0:644"
)