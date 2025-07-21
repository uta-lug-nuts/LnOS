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
# 	* this software will need to be vetted (check the sha256sum) and verify manually the GPG keys 

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

	PACKGAGES="null"
	case "$THEME" in
		"CSE")
			PACKGAGES=$(gum choose --no-limit --header "Package Choices")
			
			;;
		"CUSTOM")
			PACKGAGES=$(gum input --header "Please write out the packages you want")
			;;
	esac

done

#-----------------------------------------------------------------------------------------------------------------#

