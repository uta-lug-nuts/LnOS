



DE_CHOICE="0"
while [[ $DE_CHOICE == "0" ]]; do
		echo "Choose a Desktop Environment:"
		echo "1) Gnome"
		echo "2) Hyprland"
		echo "3) KDE"
		echo "4) XFCE"
		read -p "Enter your choice (1-4): " DE_CHOICE
		if [[ $DE_CHOICE -lt 1 || $DE_CHOICE -gt 4 ]]; then
				echo "Invalid Desktop Environment. Please choose again."
				DE_CHOICE="0"
		fi
done	

case DE_CHOICE in
	1 )
		echo "Choosen DE Gnome"
		pacman -S --noconfirm xorg xorg-server gnome gdm 
		systemctl enable --now gdm.service
		;;
	2 )
		echo "Choosen DE Hyprland"
		pacman -S --noconfirm wayland uwsm hyprland
		;;
	3 )
		echo "Choosen DE KDE"
		;;
	4 )
		echo "Choosen DE XFCE"
		;;
	* )
		echo "ERROR unknown choice"
		;;
	esac

