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
        # pacman -S --noconfirm xorg xorg-server gnome gdm
        # systemctl enable --now gdm.service
        ;;
    "Hyprland")
        echo "Chosen DE: Hyprland"
        # pacman -S --noconfirm wayland uwsm hyprland
        ;;
    "KDE")
        echo "Chosen DE: KDE"
        # pacman -S --noconfirm xorg xorg-server plasma kde-desktop sddm
		# systemctl enable --now sddm.service
        ;;
    "XFCE")
        echo "Chosen DE: XFCE"
        # pacman -S --noconfirm xorg xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
        # systemctl enable --now lightdm.service
        ;;
esac

#-----------------------------------------------------------------------------------------------------------------#

