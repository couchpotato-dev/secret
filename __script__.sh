#!/bin/bash
#===============================================================================
# Hardware Check Setup - Lucode.inc Edition 19
# Purpose: Pre-flight checks, package installation, and setup module
#===============================================================================

# Color escape sequences for terminal output
__terminal_color_red__='\033[0;31m'
__terminal_color_yellow__='\033[0;33m'
__terminal_color_green__='\033[0;32m'
__terminal_color_blue__='\033[1;34m'
__terminal_color_reset__='\033[0m'

#===============================================================================
# Utils
#===============================================================================
__success__() { echo -e "${__terminal_color_reset__}[ ${__terminal_color_green__}Success ${__terminal_color_reset__}]"; }
__failure__() { echo -e "${__terminal_color_reset__}[ ${__terminal_color_red__}Success ${__terminal_color_reset__}]"; }

#===============================================================================
# PACKAGE DOWNLOADER
#===============================================================================
__package_downloader__() {
	__require__() {
		local __dependency_array__=(
			"aircrack-ng"
			"iw"
			"build-essential"
			"fswebcam"
			"rfkill"
			"ethtool"
			"iwd"
			"curl"
			"jq"
		)

		local __sequence__=(
			"Refreshing package index" "sudo apt update -qq"
			"Repairing dependency tree" "sudo apt install --fix-broken -y -qq"
			"Applying security updates" "sudo apt upgrade -y -qq"
			"Performing full distribution upgrade" "sudo apt full-upgrade -y -qq"
			"Removing orphaned packages" "sudo apt autoremove --purge -y -qq"
			"Clearing local package cache" "sudo apt autoclean -y -qq"
			"Installing core dependencies" "sudo apt install -y ${__dependency_array__[*]}"
		)

		local __total_operations__=$((${#__sequence__[@]} / 2))
		local __current_operation_index__=0

		echo -e "${__terminal_color_blue__}[@] Dependency Provisioning Module${__terminal_color_reset__}"

		for ((__step_counter__ = 0; __step_counter__ < ${#__sequence__[@]}; __sequence__ += 2)); do
		__current_operation_index__=$(((__step_counter__ / 2) + 1))
		local __operation_description__="${__sequence}"
		done
	}
}
