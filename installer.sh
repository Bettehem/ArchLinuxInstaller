#!/bin/bash

clear
echo -e "Copyright 2015 Chris Mustola\n\nArch Linux installer tool\n-------------------------"

PROGRESS=""

#Checks if the .progress file exists
function check_start(){
	if [ -e ".progress" ]; then
		get_progress
	else
		touch .progress
		echo "0" > .progress
		get_progress
	fi
}

function get_progress(){
	PROGRESS="$(cat .progress)"
}

function set_progress(){
	echo "$1" > .progress
}

#Main part of installer
function installer(){
	if [ "$PROGRESS" -gt 0 ]; then
		continue_progress
	else
		case $PROGRESS in
		0)
			keymap_select ;;
		1)
			echo "es"
		esac
	fi
}

#If the user ends the installation process in the middle of  and relaunches the installer
function continue_progress(){
	echo "do you want to continue installation from where you were?"
}

function keymap_select(){
	echo "Do you want to view available keymaps?"
	
	echo "please select your keyboard layout:(Default is us)"
	
	set_progress "1"
	get_progress
}

check_start
installer
