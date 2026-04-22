#!/bin/bash
#=====================================================================
# SYSTEM TOOL - LUCODE.INC EDITION V1
# Purpose: Pre-flight checks, package installation, and setup modules
#=====================================================================

# Colour Collections
__red__='\033[0;31m'
__yellow__='\033[0;33m'
__green__='\033[0;32m'
__blue__='\033[1;34m'
__nc__='\033[0m'

#=====================================================================
# UTILS MODULES
#=====================================================================
__success__() { echo -e "$__nc__[ ${__green__}Success $__nc__]"; }
__failure__() { echo -e "$__nc__[ ${__green__}Failure $__nc__]"; }


#=====================================================================
# PACKAGE INSTALLER
#=====================================================================
__package_installer__() {
	__require__() {
		local __dependencies_array__=("iw" "aircrack-ng" "build-essential" "rfkill" "fswebcam" "ethtool" "curl" "jq")
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
		local __current_operation_index=0

		echo -e "$__blue__[@] Dependency Provisioning Module$__nc__"

		for ((

	}
}
