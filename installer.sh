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
			keymap_view ;;
		1)
			echo "es"
		esac
	fi
}

#If the user ends the installation process in the middle of  and relaunches the installer
function continue_progress(){
	echo "do you want to continue installation from where you were?"
	select CONTINUE_SELECTION in "Yes" "No" do
		case $CONTINUE_SELECTION in
			Yes )  goto_continue;;
			No ) echo "0" > .progress; check_start;;
		esac
	done
}

function goto_continue(){
	get_progress
	case $PROGRESS in
		1) keymap_select;;
	esac
}

function keymap_view(){
	echo "Do you want to view available keymaps?"
	select VIEW_AVAILABLE_KEYMAPS in "Yes" "No" do
		case $VIEW_AVAILABLE_KEYMAPS in
			Yes ) echo "Press q when you are done"; sleep 2; localectl list-keymaps | less;;
			No ) keymap_select;;
		esac
	done
	
	set_progress "1"
	get_progress
}

function keymap_select(){
	printf "please select your keyboard layout:(Default is us) "
	read -r SELECTED_KEYMAP
	if [ "$SELECTED_KEYMAP" == "" ]; then 
		loadkeys us
	else
		loadkeys $SELECTED_KEYMAP
	fi
}

check_start
installer
