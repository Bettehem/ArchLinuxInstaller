#!/bin/bash


#-------------------------------------------------------------------------------
#Banner-like text at start of installation
clear
echo -e "Copyright 2015 Chris Mustola\n\nArch Linux installer tool\n-------------------------"
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#Initialize variables
PROGRESS=""
SELECTED_DRIVE=""
USING_USB=""
TOTAL_PROGRESS=7
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#Tool-like functions for the installer
function set_progress(){
	echo "$1" > .progress
	get_progress
}

function get_progress(){
	PROGRESS="$(cat .progress)"
}

function show_progress(){
	get_progress
	echo "Installation progress: $PROGRESS of $TOTAL_PROGRESS"
}

function set_drive(){
	echo "$1" > .drive_details/selected_drive
	get_drive
}

function get_drive(){
	SELECTED_DRIVE="$(cat .drive_details/selected_drive)"
}

function set_using_usb(){
	echo "$1" > .drive_details/usb
	get_using_usb
}

function get_using_usb(){
	USING_USB="$(cat .drive_details/usb)"
}
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#Start of installer
function installer(){
	if [ "$1" == 1 ]; then
		goto_continue
	else
		check_start
		if [ "$PROGRESS" -gt 0 ]; then
			continue_progress
		else
		#Begins installation
		keymap_view
		fi
	fi
}

#Checks if the .progress file exists and creates one if it doesn't
#Checks if the .keyboard file exists and creates one if it doesn't
#Also checks if .drive_details directory exists and creates one if it doesn't
function check_start(){
	if [ -e ".progress" ]; then
		get_progress
	else
		touch .progress
		echo "0" > .progress
		get_progress
	fi
	
	if [ ! -e ".keyboard" ]; then
		touch .keyboard
	fi
	
	if [ ! -d ".drive_details" ]; then
		mkdir .drive_details
	fi
}
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#If the user ends the installation process in the middle of  and relaunches the installer
function continue_progress(){
	echo "do you want to continue installation from where you were?"
	select CONTINUE_SELECTION in "Yes" "No"; do
		case $CONTINUE_SELECTION in
			Yes ) goto_continue; break;;
			No ) rm -r .progress; rm -r .drive_details; rm -r .keyboard; installer; break;;
		esac
	done
}

function goto_continue(){
	clear
	get_progress
	case $PROGRESS in
		1) keymap_select;;
		2) disk_get;;
		3) disk_partition;;
		4) disk_partitioned;;
		5) filesystems;;
		6) mounting_partitions;;
		7) install_base;;
		8) fstab;;
		9) timezone;;
		10) chrooting;;
		11) root_password;;
	esac
}
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#Installer functions

#Part 0
function keymap_view(){
	show_progress
	echo "Do you want to view available keymaps?"
	select VIEW_AVAILABLE_KEYMAPS in "Yes" "No"; do
		case $VIEW_AVAILABLE_KEYMAPS in
			Yes ) echo "Press q when you are done with viewing keymaps"; sleep 2; localectl list-keymaps | less; set_progress "1"; clear; keymap_select; break;;
			No ) set_progress "1"; clear; keymap_select; break;;
		esac
	done
}

#Part 1
function keymap_select(){
	show_progress
	printf "please select your keyboard layout:(Default is us) "
	read -r SELECTED_KEYMAP
	if [ "$SELECTED_KEYMAP" == "" ]; then 
		loadkeys us
		echo "us" > .keyboard
	else
		loadkeys $SELECTED_KEYMAP
		echo "$SELECTED_KEYMAP" > .keyboard
	fi
	
	clear
	set_progress "2"
	disk_get
}

#Part 2
function disk_get(){
	show_progress
	echo "Listing disks:"
	lsblk
	printf "select your device(for example \"/dev/sda\"): "
	read -r SELECTED_DRIVE
	echo "Are you sure you want to use $SELECTED_DRIVE as your drive for this installation?"
	select DRIVE_SELECTION_CONFIRMATION in "Yes" "No"; do
		case $DRIVE_SELECTION_CONFIRMATION in
			Yes) set_progress "3"; clear; disk_partition; break;;
			No) disk_get; break;;
		esac
	done
}

#Part 3
function disk_partition(){
	show_progress
	set_drive "$SELECTED_DRIVE"
	echo "Do you want to partition $SELECTED_DRIVE?"
	echo -e "WARNING! IT IS NOT RECOMMENDED TO CREATE A SWAP PARTITION IF\nYOU ARE INSTALLING ON TO A USB DRIVE!"
	select DRIVE_PARTITION in "Yes" "No"; do
		case $DRIVE_PARTITION in
			Yes) cfdisk $SELECTED_DRIVE; set_progress "4"; clear; disk_partitioned; break;;
			No) set_progress "4"; clear; disk_partitioned; break;;
		esac
	done
}

#Part 4
function disk_partitioned(){
	show_progress
	
	boot_created
	root_created
	home_created
	swap_created
	
	set_progress "5"
	clear
	filesystems
}
#These are for Part 4
#################################################################################
function boot_created(){
	printf "Did you create a boot partition?[y/n]: "
	read -r CREATED_BOOT
	if [ "$CREATED_BOOT" == "y" ]; then
		printf "Enter partition number\n(for example if your boot partition is /dev/sda1 enter \"1\"): "
		read -r BOOT_PARTITION
		echo "$SELECTED_DRIVE$BOOT_PARTITION" > .drive_details/boot
		echo ""
	elif [ "$CREATED_BOOT" == "Y" ]; then
		printf "Enter partition number\n(for example if your boot partition is /dev/sda1 enter \"1\"): "
		read -r BOOT_PARTITION
		echo "$SELECTED_DRIVE$BOOT_PARTITION" > .drive_details/boot
		echo ""
	elif [ "$CREATED_BOOT" == "n" ]; then
		echo ""
	elif [ "$CREATED_BOOT" == "N" ]; then
		echo ""
	else
		clear
		boot_created
	fi
}

function root_created(){
	printf "Did you create a root partition?[y/n]: "
	read -r CREATED_ROOT
	if [ "$CREATED_ROOT" == "y" ]; then
		printf "Enter partition number\n(for example if your root partition is /dev/sda2 enter \"2\"): "
		read -r ROOT_PARTITION
		echo "$SELECTED_DRIVE$ROOT_PARTITION" > .drive_details/root
		echo ""
	elif [ "$CREATED_ROOT" == "Y" ]; then
		printf "Enter partition number\n(for example if your root partition is /dev/sda2 enter \"2\"): "
		read -r ROOT_PARTITION
		echo "$SELECTED_DRIVE$ROOT_PARTITION" > .drive_details/root
		echo ""
	elif [ "$CREATED_ROOT" == "n" ]; then
		echo ""
	elif [ "$CREATED_ROOT" == "N" ]; then
		echo ""
	else
		root_created
	fi
}

function home_created(){
	printf "Did you create a home partition?[y/n]: "
	read -r CREATED_HOME
	if [ "$CREATED_HOME" == "y" ]; then
		printf "Enter partition number\n(for example if your home partition is /dev/sda3 enter \"3\"): "
		read -r HOME_PARTITION
		echo "$SELECTED_DRIVE$HOME_PARTITION" > .drive_details/home
		echo ""
	elif [ "$CREATED_HOME" == "Y" ]; then
		printf "Enter partition number\n(for example if your home partition is /dev/sda3 enter \"3\"): "
		read -r HOME_PARTITION
		echo "$SELECTED_DRIVE$HOME_PARTITION" > .drive_details/home
		echo ""
	elif [ "$CREATED_HOME" == "n" ]; then
		echo ""
	elif [ "$CREATED_HOME" == "N" ]; then
		echo ""
	else
		home_created
	fi
}

function swap_created(){
	printf "Did you create a swap partition?[y/n]: "
	read -r CREATED_SWAP
	if [ "$CREATED_SWAP" == "y" ]; then
		printf "Enter partition number\n(for example if your swap partition is /dev/sda4 enter \"4\"): "
		read -r SWAP_PARTITION
		echo "$SELECTED_DRIVE$SWAP_PARTITION" > .drive_details/swap
		echo ""
	elif [ "$CREATED_SWAP" == "Y" ]; then
		printf "Enter partition number\n(for example if your swap partition is /dev/sda4 enter \"4\"): "
		read -r SWAP_PARTITION
		echo "$SELECTED_DRIVE$SWAP_PARTITION" > .drive_details/swap
		echo ""
	elif [ "$CREATED_SWAP" == "n" ]; then
		echo ""
	elif [ "$CREATED_SWAP" == "N" ]; then
		echo ""
	else
		swap_created
	fi
}
#################################################################################

#Part 5
function filesystems(){
	show_progress
	
	using_usb
	if [ -f ".drive_details/boot" ]; then
		boot_filesystem
	fi
	if [ -f ".drive_details/root" ]; then
		root_filesystem
	fi
	if [ -f ".drive_details/home" ]; then
		home_filesystem
	fi
	mkswap "$SELECTED_DRIVE$SWAP_PARTITION"
	
	set_progress "6"
	clear
	mounting_partitions
}
#These are for Part 5
#################################################################################
function using_usb(){
	printf "Are you installing your system on to a usb stick?[y/n] "
	read -r DRIVE_IS_USB
	if [ "$DRIVE_IS_USB" == "y" ]; then
		set_using_usb "1"
	elif [ "$DRIVE_IS_USB" == "Y" ]; then
		set_using_usb "1"
	elif [ "$DRIVE_IS_USB" == "n" ]; then
		set_using_usb "0"
	elif [ "$DRIVE_IS_USB" == "N" ]; then
		set_using_usb "0"
	else
		using_usb
	fi
}

function boot_filesystem(){
	if [ "$USING_USB" == "1" ]; then
		printf "Enter a label for your boot partition.\nThis is recommended to ensure compatibility between machines(for example \"arch_usb_boot\"): "
		read -r BOOT_LABEL
		echo "The boot partiton will be labelled as $BOOT_LABEL."
		echo "$BOOT_LABEL" > .drive_details/boot_label
		
		echo -e "Only ext2 and ext4 are supported with labels in this installation.\nIf you choose another filesystem, you have to label it manually."
		echo -e "What filesystem do you want for your boot partition?\n(ext2 or ext4 recommended)"
		select FILESYSTEM_BOOT in "ext2" "ext4" "other"; do
			case $FILESYSTEM_BOOT in
				ext2) mkfs.ext2 -L $BOOT_LABEL "$SELECTED_DRIVE$BOOT_PARTITION"; echo "ext2" > .drive_details/boot_filesystem; echo ""; break;;
				ext4) mkfs.ext4 -L $BOOT_LABEL "$SELECTED_DRIVE$BOOT_PARTITION"; echo "ext4" > .drive_details/boot_filesystem; echo ""; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_BOOT_FILESYSTEM; echo "$CUSTOM_BOOT_FILESYSTEM" > .drive_details/custom_boot_filesystem; mkfs."$CUSTOM_BOOT_FILESYSTEM" "$SELECTED_DRIVE$BOOT_PARTITION"; echo ""; break;;
			esac
		done
	else
		echo -e "What filesystem do you want for your boot partition?\n(ext2 or ext4 recommended)"
		select FILESYSTEM_BOOT in "ext2" "ext4" "other"; do
			case $FILESYSTEM_BOOT in
				ext2) mkfs.ext2 "$SELECTED_DRIVE$BOOT_PARTITION"; echo "ext2" > .drive_details/boot_filesystem; echo ""; break;;
				ext4) mkfs.ext4 "$SELECTED_DRIVE$BOOT_PARTITION"; echo "ext4" > .drive_details/boot_filesystem; echo ""; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_BOOT_FILESYSTEM; echo "$CUSTOM_BOOT_FILESYSTEM" > .drive_details/custom_boot_filesystem; mkfs."$CUSTOM_BOOT_FILESYSTEM" "$SELECTED_DRIVE$BOOT_PARTITION"; echo ""; break;;
			esac
		done
	fi
}

function root_filesystem(){
	if [ "$USING_USB" == "1" ]; then
		printf "Enter a label for your root partition.\nThis is recommended to ensure compatibility between machines(for example \"arch_usb_root\"): "
		read -r ROOT_LABEL
		echo "The root partiton will be labelled as $ROOT_LABEL."
		echo "$ROOT_LABEL" > .drive_details/root_label
		
		echo -e "Only f2fs and ext4 are supported with labels in this installation.\nIf you choose another filesystem, you have to label it manually."
		echo -e "What filesystem do you want for your root partition?\n(f2fs recommended for usb installation)"
		select FILESYSTEM_ROOT in "f2fs" "ext4" "other"; do
			case $FILESYSTEM_ROOT in
				f2fs) mkfs.f2fs -l $ROOT_LABEL "$SELECTED_DRIVE$ROOT_PARTITION"; echo "f2fs" > .drive_details/root_filesystem; echo ""; break;;
				ext4) mkfs.ext4 -L $ROOT_LABEL "$SELECTED_DRIVE$ROOT_PARTITION"; echo "ext4" > .drive_details/root_filesystem; echo ""; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_ROOT_FILESYSTEM; echo "$CUSTOM_ROOT_FILESYSTEM" > .drive_details/custom_root_filesystem; mkfs."$CUSTOM_ROOT_FILESYSTEM" "$SELECTED_DRIVE$ROOT_PARTITION"; echo ""; break;;
			esac
		done
	else
		echo "What filesystem do you want for your root partition? (ext4 recommended)"
		select FILESYSTEM_ROOT in "ext4" "other"; do
			case $FILESYSTEM_ROOT in
				ext4) mkfs.ext2 "$SELECTED_DRIVE$ROOT_PARTITION"; echo "ext4" > .drive_details/root_filesystem; echo ""; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_ROOT_FILESYSTEM; echo "$CUSTOM_ROOT_FILESYSTEM" > .drive_details/custom_root_filesystem; mkfs."$CUSTOM_ROOT_FILESYSTEM" "$SELECTED_DRIVE$ROOT_PARTITION"; echo ""; break;;
			esac
		done
	fi
}

function home_filesystem(){
	if [ "$USING_USB" == "1" ]; then
		printf "Enter a label for your home partition.\nThis is recommended to ensure compatibility between machines(for example \"arch_usb_home\"): "
		read -r HOME_LABEL
		echo "The home partiton will be labelled as $HOME_LABEL."
		echo "$HOME_LABEL" > .drive_details/home_label
		
		echo -e "Only f2fs and ext4 are supported with labels in this installation.\nIf you choose another filesystem, you have to label it manually."
		echo -e "What filesystem do you want for your home partition?\n(f2fs recommended for usb installation)"
		select FILESYSTEM_HOME in "f2fs" "ext4" "other"; do
			case $FILESYSTEM_HOME in
				f2fs) mkfs.f2fs -l $HOME_LABEL "$SELECTED_DRIVE$HOME_PARTITION"; echo "f2fs" > .drive_details/home_filesystem; echo ""; break;;
				ext4) mkfs.ext4 -L $HOME_LABEL "$SELECTED_DRIVE$HOME_PARTITION"; echo "ext4" > .drive_details/home_filesystem; echo ""; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_HOME_FILESYSTEM; echo "$CUSTOM_HOME_FILESYSTEM" > .drive_details/custom_home_filesystem; mkfs."$CUSTOM_HOME_FILESYSTEM" "$SELECTED_DRIVE$HOME_PARTITION"; echo ""; break;;
			esac
		done
	else
		echo "What filesystem do you want for your home partition? (ext4 recommended)"
		select FILESYSTEM_HOME in "ext4" "other"; do
			case $FILESYSTEM_HOME in
				ext4) mkfs.ext2 "$SELECTED_DRIVE$HOME_PARTITION"; echo "ext4" > .drive_details/home_filesystem; echo ""; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_HOME_FILESYSTEM; echo "$CUSTOM_HOME_FILESYSTEM" > .drive_details/custom_home_filesystem; mkfs."$CUSTOM_HOME_FILESYSTEM" "$SELECTED_DRIVE$HOME_PARTITION"; echo ""; break;;
			esac
		done
	fi
}
#################################################################################

#Part 6
function mounting_partitions(){
	show_progress
	echo "Mounting partitions..."
	mount "$SELECTED_DRIVE$ROOT_PARTITION" /mnt
	if [ -f ".drive_details/boot" ]; then
		mkdir /mnt/boot
		mount "$SELECTED_DRIVE$BOOT_PARTITION" /mnt/boot
	fi
	if [ -f ".drive_details/home" ]; then
		mkdir /mnt/home
		mount "$SELECTED_DRIVE$HOME_PARTITION" /mnt/home
	fi
	
	set_progress "7"
	clear
	install_base
}

#Part 7
function install_base(){
	show_progress
	pacstrap /mnt base base-devel
	echo "Base system installed"
	
	set_progress "8"
	clear
	fstab
}

#Part 8
function fstab(){
	show_progress
	echo "Generating fstab..."
	genfstab -L /mnt > /mnt/etc/fstab
	echo "Generated fstab."
	
	set_progress "9"
	clear
	timezone
}

#Part 9
function timezone(){
	show_progress
	echo "Listing timezones. press \"q\" when you are done. Press enter to continue"
	read
	timedatectl list-timezones
	clear
	printf "Enter your timezone (For example \"Europe/Helsinki\"): "
	read -r TIMEZONE
	echo "Setting timezone to $TIMEZONE"
	ln -s /mnt/usr/share/zoneinfo/$TIMEZONE /mnt/etc/localtime
	
	set_progress "10"
	clear
	chrooting
}

#Part 10
function chrooting(){
	show_progress
	echo "Copying installer files in to /mnt/root/ArchLinuxInstaller"
	mkdir /mnt/root/ArchLinuxInstaller
	cp -a * /mnt/root/ArchLinuxInstaller/.
	cp -a .* /mnt/root/ArchLinuxInstaller/.
	
	set_progress "11"
	
	echo "Chrooting in to /mnt and launching installer.."
	arch-chroot /mnt ./root/ArchLinuxInstaller/installer.sh "1"
	clear
	finish_install
}

#Continuing from here, the installer will be executed in chroot
#Part 11
function root_password(){
	show_progress
	printf "Do you want to set a password for the root user? This is highly recommended[y/n]: "
	read -r ROOT_PASSWORD
	if [ "$ROOT_PASSWORD" == "y" ]; then
		passwd
	elif [ "$ROOT_PASSWORD" == "Y" ]; then
		passwd
	elif [ "$ROOT_PASSWORD" == "n" ]; then
		echo ""
	elif [ "$ROOT_PASSWORD" == "N" ]; then
		echo ""
	else
		root_password
	fi
	
	set_progress "12"
	clear
	locale_setting
}

#Part 12
function locale_setting(){
	show_progress
	printf "Next you have to use nano to uncomment all the locales you want to be available.\nWhen you are done, press CTRL+O (the letter O) to save.\nThen press CTRL+X to exit the editor.\nPress enter to continue."
	read -r
	nano /etc/locale.gen
	locale-gen
	echo "listing locales. press \"q\" when you know which one you want to use."
	localectl list-locales | less
	printf "Enter the locale you want to use as it is dispalyed.\nFor example \"en_US.utf8\": "
	read -r USER_LOCALE
	localectl set-locale LOCALE=$USER_LOCALE
	
	set_progress "13"
	clear
	set_keyboard
}

#Part 13
function set_keyboard(){
	show_progress
	echo "Setting keyboard layout to $(cat .keyboard)"
	localectl set-keymap --no-convert "$(cat .keyboard)"
	localectl set-x11-keymap --no-convert "$(cat .keyboard)"
	
	set_progress "14"
	clear
	set_hostname
}

#Part 14
function set_hostname(){
	show_progress
	printf "Enter a hostname for your computer(Name of your computer): "
	read -r COMPUTER_HOSTNAME
	echo "$COMPUTER_HOSTNAME" > /etc/hostname
	
	set_progress "15"
	clear
	set_multilib
}

#Part 15
function set_multilib(){
	show_progress
	echo "checking if multilib is required..."
	if [ uname -a == "x86_64" ]; then
		echo "Enabling multilib..."
		if [ grep -q "#\[multilib\]" /etc/pacman.conf ]; then
        	sed -i '/\[multilib\]/{ s/^#//; n; s/^#//; }' /etc/pacman.conf
		elif [ ! grep -q "\[multilib\]" /etc/pacman.conf ]; then
        	printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist" \ 
			>> /etc/pacman.conf
		fi
	fi
	
	set_progress "16"
	clear
	set_yaourt
}

#Part 16
function set_yaourt(){
	show_progress
	echo "Enabling yaourt..."
	if [ grep -q "#\[archlinuxfr\]" /etc/pacman.conf ]; then
        sed -i '/\[archlinuxfr\]/{ s/^#//; n; s/^#//; }' /etc/pacman.conf
	elif [ ! grep -q "\[archlinuxfr\]" /etc/pacman.conf ]; then
        printf "[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/\$arch\n" \ 
		>> /etc/pacman.conf
	fi
	pacman -Sy yaourt --noconfirm --needed
	set_progress "17"
	clear
	grub_setup
}

#Part 17
function grub_setup(){
	show_progress
	printf "Do you want to install grub?(Recommended)[y/n]: "
	read -r GRUB_INSTALL
	if [ "$GRUB_INSTALL" == "y" ]; then
		pacman -Sy grub-bios --noconfirm --needed
	elif [ "$GRUB_INSTALL" == "Y" ]; then
		pacman -Sy grub-bios --noconfirm --needed
	elif [ "$GRUB_INSTALL" == "n" ]; then
		pacman -Sy grub-bios --noconfirm --needed
	elif [ "$GRUB_INSTALL" == "N" ]; then
		pacman -Sy grub-bios --noconfirm --needed
	else
		grub_setup
	fi
	
	set_progress "18"
	clear
	check_multiboot
}



#Part 18
function check_multiboot(){
	show_progress
	get_using_usb
	if [ "$USING_USB" == "1" ]; then
		echo ""
	else
		printf "Do you have another os installed alongside arch?[y/n]: "
		read -r MULTI_OS
		if [ $MULTI_OS == "y" ]; then
			pacman -Sy os-prober --noconfirm --needed
			os-prober
		elif [ $MULTI_OS == "Y" ]; then
			pacman -Sy os-prober --noconfirm --needed
			os-prober
		elif [ $MULTI_OS == "n" ]; then
			echo ""
		elif [ $MULTI_OS == "N" ]; then
			echo ""
		else
			check_multiboot
		fi
	fi
	
	set_progress "19"
	clear
	install_grub
}

#Part 19
function install_grub(){
	show_progress
	
	get_drive
	grub-install $SELECTED_DRIVE
	
	get_using_usb
	
	if [ "$USING_USB" == "1" ]; then
		pacman -Sy f2fs-tools --noconfirm --needed
	fi
	
	mkinitcpio -p linux
	if [ "$USING_USB" == "1" ]; then
		if [ grep -q "#GRUB_DISABLE_LINUX_UUID=\"true\"" /etc/default/grub ]; then
        	sed -i '/GRUB_DISABLE_LINUX_UUID=\"true\"/{ s/^#//;}' /etc/default/grub
		fi
	fi
	grub-mkconfig -o /boot/grub/grub.cfg
	if [ "$USING_USB" == "1" ]; then
		sed -i "s/$SELECTED_DRIVE$ROOT_PARTITION/g" /boot/grub/grub.cfg
	fi
	
	set_progress "20"
	clear
	network
}



#Part 20
function network(){
	show_progress
	
	connman_install
	network_manager_install
	systemctl enable dhcpcd
	
	set_progress "21"
	clear
	normal_user
}

#These are for Part 20
#################################################################################
function connman_install(){
	printf "Do you want to install connman?(Recommended for easy usage)[y/n]: "
	read -r CONNMAN
	if [ "$CONNMAN" == "y" ]; then
		pacman -S connman --noconfirm --needed
		systemctl enable connman
		printf "Enable wifi?[y/n]: "
		read -r ENABLE_WIFI
		if [ "$ENABLE_WIFI" == "y" ]; then
			connmanctl enable wifi
		elif [ "$ENABLE_WIFI" == "Y" ]; then
			connmanctl enable wifi
		elif [ "$ENABLE_WIFI" == "n" ]; then
			echo ""
		elif [ "$ENABLE_WIFI" == "N" ]; then
			echo ""
		else
			connman_install
		fi
	elif [ "$CONNMAN" == "Y" ]; then
		pacman -S connman --noconfirm --needed
		systemctl enable connman
	elif [ "$CONNMAN" == "n" ]; then
		echo ""
	elif [ "$CONNMAN" == "N" ]; then
		echo ""
	else
		connman_install
	fi
}

function networkmanager_install(){
	printf "Do you want to install networkmanager?(Recommended for easy usage)[y/n]: "
	read -r NETWORKMANAGER
	if [ "$NETWORKMANAGER" == "y" ]; then
		pacman -S networkmanager --noconfirm --needed
		systemctl enable networkmanager
	elif [ "$NETWORKMANAGER" == "Y" ]; then
		pacman -S networkmanager --noconfirm --needed
		systemctl enable networkmanager
	elif [ "$NETWORKMANAGER" == "n" ]; then
		echo ""
	elif [ "$NETWORKMANAGER" == "N" ]; then
		echo ""
	else
		networkmanager_install
	fi
}
#################################################################################

#Part 21
function normal_user(){
	show_progress

	printf "Add a normal user?(Recommended)[y/n]: "
	read -r ADD_USER
	if [ "$ADD_USER" == "y" ]; then
		printf "An username can onky contain lower-case letters and can not contain spaces.\nEnter username: "
		read -r USERNAME
		useradd -m -g users -G storage,power,wheel -s /bin/bash $USERNAME
		passwd $USERNAME
	elif [ "$ADD_USER" == "Y" ]; then
		printf "An username can onky contain lower-case letters and can not contain spaces.\nEnter username: "
		read -r USERNAME
		useradd -m -g users -G storage,power,wheel -s /bin/bash $USERNAME
		passwd $USERNAME
	elif [ "$ADD_USER" == "n" ]; then
		echo ""
	elif [ "$ADD_USER" == "N" ]; then
		echo ""
	else
		normal_user
	fi
	
	set_progress "22"
	clear
	exit
}

#Part 22
function finish_install(){
	show_progress
	echo "Unmounting partitions..."
	if [ -f ".drive_details/boot" ]; then
		umount /mnt/boot
	fi
	if [ -f ".drive_details/home" ]; then
		umount /mnt/home
	fi
	umount /mnt
	
	echo -e "Done. Press enter to shut down the computer.\nThen remove the installation media and enjoy your new arch linux system!"
	read
	shutdown -h now
}
#-------------------------------------------------------------------------------




#Used to launch the script
installer "$1"
