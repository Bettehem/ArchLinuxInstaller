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
TOTAL_PROGRESS=2
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
	SELECTED_DRIVE="$(cat .drive_details/selected_drive"
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
	
	if [! -d ".drive_details" ]; then
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
			No ) echo "0" > .progress; installer; break;;
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
}

function boot_created(){
	printf "Did you create a separate boot partition?[y/n]"
	read -r CREATED_BOOT
	if [ "$CREATED_BOOT" == "y" ]; then
		printf "Enter partition number (for example if your boot partition is ): "
	elif [ "$CREATED_BOOT" == "Y" ]; then
	
	elif [ "$CREATED_BOOT" == "n" ]; then
	
	elif [ "$CREATED_BOOT" == "N" ]; then
	
	else
		clear
		boot_created
	fi
}
#-------------------------------------------------------------------------------




#Used to launch the script
installer
