#!/bin/bash

# Copyright 2025 The LugNuts Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.

# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# goals of this file:
# * allow users to choose a DE
# * allow users to select the type of student they are (CSE, SWE, or Custom)
# 	* after selection of type of student open a drop down of selected software to install
# 	* this software will need to be vetted (check the sha256sum) and verify manually the GPG keys for AUR (arch user repository)
#     * For pacman software that's checksumed and GPG signed, so there's no need to check
#     * I am considering manual installation of the repo's instead of installation with paru 

# This assumes the autosetup location is in a place that wont break the system

gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Hello, there. Welcome to LNOS auto setup script"

#------------------------------------------------- DE INSTALLATION -------------------------------------------------#

while true; do
    DE_CHOICE=$(gum choose --header "Choose your Desktop Environment(DE):" "Gnome" "Hyprland" "KDE" "XFCE" "Skip DE Install")

	if [[ "$DE_CHOICE" == "Skip DE Install" ]]; then
		echo "Skipping DE installation."
		break
	fi

    gum confirm "You selected: $DE_CHOICE. Proceed with installation?" && break

    echo "Returning to selection menu..."
done

case "$DE_CHOICE" in
    "Gnome")
        echo "Chosen DE: Gnome"
        pacman -S --noconfirm xorg xorg-server gnome gdm
        systemctl enable --now gdm.service
        ;;
    "Hyprland")
        echo "Chosen DE: Hyprland"
        pacman -S --noconfirm wayland uwsm hyprland
        ;;
    "KDE")
        echo "Chosen DE: KDE"
        pacman -S --noconfirm xorg xorg-server plasma kde-desktop sddm
		systemctl enable --now sddm.service
        ;;
    "XFCE")
        echo "Chosen DE: XFCE"
        pacman -S --noconfirm xorg xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
        systemctl enable --now lightdm.service
        ;;
esac

#-----------------------------------------------------------------------------------------------------------------#




#-------------------------------------------Package Installation Themes-------------------------------------------#

while true; do
    THEME=$(gum choose --header "Choose your installation Profile:" "CSE" "Custom")

    gum confirm "You selected: $THEME. Proceed with installation?" && break

done

# Display Multiple selectable choices of packages to install 
# We will store all packages in packages.txt
while true; do

	PACMAN_PACKGAGES="null"

	# As of now we wont enable paru since Arch User Repository isn't signed
	# we will instead try to clone AUR packages and manually makepkg and verify them with sha256sum and ensure the GPG key is signed on Github
	
	# when installing paru make sure you download a released tag that's been signed and verified
	# the one below will get the most recent version
	# echo "Installing paru"
	# sudo pacman -S --needed base-devel
	# git clone https://aur.archlinux.org/paru.git
	# cd paru
	# makepkg -si
	# cd ..
	# rm -rf paru

	case "$THEME" in
		"CSE")
			PACMAN_PACKGAGES=$(cat pacman_packages/CSE_packages.txt | gum choose --no-limit --header "Pacman Package Choices")
			# delimit packages selected by \n
			PACMAN_PACKAGES=$(echo "$PACMAN_PACKAGES" | tr ' ' '\n')

			# gum log --structured --level warning "Arch User Repository (AUR) isn't GPG signed and Verified, anyone can upload to it"
			# gum log --structured --level warning "Selections below are hand picked and verified manually for this reason"

			# PARU_PACKAGES=$(gum choose --no-limit --header "AUR Package Choices")
			# PARU_PACKAGES=$(echo "$PARU_PACKAGES" | tr ' ' '\n')
			
			gum confirm "Happy with your selection ?" 

			# download packages using pacman 

			gum spin --spinner dot --title "Installing pacman packages..." -- sudo pacman -S $PACMAN_PACKAGES --noconfirm
			# gum spin --spinner dot --title "Installing paru packages..." -- paru -S $PARU_PACACKAGES --noconfirm
			;;
		"CUSTOM")
			PACMAN_PACKGAGES=$(gum input --header "Please write out the packages you want")
			;;
	esac

done

#-----------------------------------------------------------------------------------------------------------------#

