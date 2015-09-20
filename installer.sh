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
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#Start of installer
function installer(){
	check_start
	if [ "$PROGRESS" -gt 0 ]; then
		continue_progress
	else
		#Begins installation
		keymap_view
	fi
}

#Checks if the .progress file exists and creates one if it doesn't
#Also checks if .drive_details directory exists and creates one if it doesn't
function check_start(){
	if [ -e ".progress" ]; then
		get_progress
	else
		touch .progress
		echo "0" > .progress
		get_progress
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
			No ) rm -r .progress; if [ -d ".drive_details" ]; then; rm -r .drive_details; fi; installer; break;;
		esac
	done
}

function goto_continue(){
	get_progress
	case $PROGRESS in
		1) keymap_select;;
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
	else
		loadkeys $SELECTED_KEYMAP
	fi
	clear
	set_progress "2"
	get_progress
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
	echo "WARNING! IT\'S NOT RECOMMENDED TO CREATE A SWAP PARTITION IF YOU ARE INSTALLING ON TO A USB DRIVE!"
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
		echo "$SELECTED_DRIVE/$BOOT_PARTITION" > .drive_details/boot
	elif [ "$CREATED_BOOT" == "Y" ]; then
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
		echo "$SELECTED_DRIVE/$ROOT_PARTITION" > .drive_details/root
	elif [ "$CREATED_ROOT" == "Y" ]; then
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
	printf "Did you create a root partition?[y/n]: "
	read -r CREATED_HOME
	if [ "$CREATED_HOME" == "y" ]; then
		printf "Enter partition number\n(for example if your home partition is /dev/sda3 enter \"3\"): "
		read -r HOME_PARTITION
		echo "$SELECTED_DRIVE/$HOME_PARTITION" > .drive_details/home
	elif [ "$CREATED_HOME" == "Y" ]; then
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
	printf "Did you create a root partition?[y/n]: "
	read -r CREATED_SWAP
	if [ "$CREATED_SWAP" == "y" ]; then
		printf "Enter partition number\n(for example if your swap partition is /dev/sda4 enter \"4\"): "
		read -r SWAP_PARTITION
		echo "$SELECTED_DRIVE/$SWAP_PARTITION" > .drive_details/swap
	elif [ "$CREATED_SWAP" == "Y" ]; then
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
	mkswap "$SELECTED_DRIVE/$SWAP_PARTITION"
	
	set_progress "6"
	clear
	mounting_partitions
}
#These are for Part 5
#################################################################################
function using_usb(){
	printf "Are you installing your system on to a usb stick?[y/n] "
	read -r USING_USB
	if [ "$USING_USB" == "y" ]; then
		echo "1" > .drive_details/usb
	elif [ "$USING_USB" == "Y" ]; then
		echo ""
	elif [ "$USING_USB" == "n" ]; then
		echo ""
	elif [ "$USING_USB" == "N" ]; then
		echo ""
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
		
		echo -e "Only f2fs and ext4 are supported with labels in this installation.\nIf you choose another filesystem, you have to label it manually."
		echo "What filesystem do you want for your root partition? (f2fs recommended for usb installation)"
		select FILESYSTEM_BOOT in "f2fs" "ext4" "other"; do
			case $FILESYSTEM_BOOT in
				f2fs) mkfs.f2fs -L $BOOT_LABEL "$SELECTED_DRIVE/$BOOT_PARTITION"; echo "f2fs" > .drive_details/boot_filesystem; break;;
				ext4) mkfs.ext4 -L $BOOT_LABEL "$SELECTED_DRIVE/$BOOT_PARTITION"; echo "ext4" > .drive_details/boot_filesystem; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_BOOT_FILESYSTEM; echo "$CUSTOM_BOOT_FILESYSTEM" > .drive_details/custom_boot_filesystem; mkfs."$CUSTOM_BOOT_FILESYSTEM" "$SELECTED_DRIVE/$BOOT_PARTITION"; break;;
			esac
		done
	else
		echo "What filesystem do you want for your boot partition? (ext2 or ext4 recommended)"
		select FILESYSTEM_BOOT in "ext2" "ext4" "other"; do
			case $FILESYSTEM_BOOT in
				ext2) mkfs.ext2 "$SELECTED_DRIVE/$BOOT_PARTITION"; echo "ext2" > .drive_details/boot_filesystem; break;;
				ext4) mkfs.ext4 "$SELECTED_DRIVE/$BOOT_PARTITION"; echo "ext4" > .drive_details/boot_filesystem; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_BOOT_FILESYSTEM; echo "$CUSTOM_BOOT_FILESYSTEM" > .drive_details/custom_boot_filesystem; mkfs."$CUSTOM_BOOT_FILESYSTEM" "$SELECTED_DRIVE/$BOOT_PARTITION"; break;;
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
		echo "What filesystem do you want for your root partition? (f2fs recommended for usb installation)"
		select FILESYSTEM_ROOT in "f2fs" "ext4" "other"; do
			case $FILESYSTEM_ROOT in
				f2fs) mkfs.f2fs -L $ROOT_LABEL "$SELECTED_DRIVE/$ROOT_PARTITION"; echo "f2fs" > .drive_details/root_filesystem; break;;
				ext4) mkfs.ext4 -L $ROOT_LABEL "$SELECTED_DRIVE/$ROOT_PARTITION"; echo "ext4" > .drive_details/root_filesystem; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_ROOT_FILESYSTEM; echo "$CUSTOM_ROOT_FILESYSTEM" > .drive_details/custom_root_filesystem; mkfs."$CUSTOM_ROOT_FILESYSTEM" "$SELECTED_DRIVE/$ROOT_PARTITION"; break;;
			esac
		done
	else
		echo "What filesystem do you want for your root partition? (ext4 recommended)"
		select FILESYSTEM_ROOT in "ext4" "other"; do
			case $FILESYSTEM_ROOT in
				ext4) mkfs.ext2 "$SELECTED_DRIVE/$ROOT_PARTITION"; echo "ext4" > .drive_details/root_filesystem; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_ROOT_FILESYSTEM; echo "$CUSTOM_ROOT_FILESYSTEM" > .drive_details/custom_root_filesystem; mkfs."$CUSTOM_ROOT_FILESYSTEM" "$SELECTED_DRIVE/$ROOT_PARTITION"; break;;
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
		echo "What filesystem do you want for your home partition? (f2fs recommended for usb installation)"
		select FILESYSTEM_HOME in "f2fs" "ext4" "other"; do
			case $FILESYSTEM_HOME in
				f2fs) mkfs.f2fs -L $HOME_LABEL "$SELECTED_DRIVE/$HOME_PARTITION"; echo "f2fs" > .drive_details/home_filesystem; break;;
				ext4) mkfs.ext4 -L $HOME_LABEL "$SELECTED_DRIVE/$HOME_PARTITION"; echo "ext4" > .drive_details/home_filesystem; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_HOME_FILESYSTEM; echo "$CUSTOM_HOME_FILESYSTEM" > .drive_details/custom_home_filesystem; mkfs."$CUSTOM_HOME_FILESYSTEM" "$SELECTED_DRIVE/$HOME_PARTITION"; break;;
			esac
		done
	else
		echo "What filesystem do you want for your home partition? (ext4 recommended)"
		select FILESYSTEM_HOME in "ext4" "other"; do
			case $FILESYSTEM_HOME in
				ext4) mkfs.ext2 "$SELECTED_DRIVE/$HOME_PARTITION"; echo "ext4" > .drive_details/home_filesystem; break;;
				other) printf "Enter filesystem to be used: "; read -r CUSTOM_HOME_FILESYSTEM; echo "$CUSTOM_HOME_FILESYSTEM" > .drive_details/custom_home_filesystem; mkfs."$CUSTOM_HOME_FILESYSTEM" "$SELECTED_DRIVE/$HOME_PARTITION"; break;;
			esac
		done
	fi
}
#################################################################################

#Part 6
function mounting_partitions(){
	show_progress
	echo "Mounting partitions..."
	mount "$SELECTED_DRIVE/$ROOT_PARTITION" /mnt
	if [ -f ".drive_details/boot" ]; then
		mkdir /mnt/boot
		mount "$SELECTED_DRIVE/$ROOT_PARTITION" /mnt/boot
	fi
	if [ -f ".drive_details/home" ]; then
		mkdir /mnt/home
		mount "$SELECTED_DRIVE/$HOME_PARTITION" /mnt/home
	fi
	
	set_progress "7"
	clear
	install_base
}

#Part 7
function install_base(){
	show_progress
	pacstrap /mnt base base-devel
}
#-------------------------------------------------------------------------------




#Used to launch the script
installer
