#!/bin/bash

Get_Card() { iw dev | awk '$1=="Interface"{print $2}' | head -n 1; }
Get_Current_Card_Mode() { iw dev "$(Get_Card)" info 2>/dev/null | awk '/type/ {print $2}'; }

CHECK_REQUIREMENTS() {
	Check_Internet_Connection() {
		Get_Public_Ip() { curl -s --max-time 3 https://api.ipify.org 2>/dev/null; }
		Get_Mac_Address() { iw dev "$(Get_Card)" info | awk '/addr/ {print $2}'; }
		Get_Loc() { IFs=',' read -r lat long <<< "$(curl -s ipinfo.io/loc)"; echo "$lat $lon"; }
		Get_Timestamp() { date +"%Y:%m:%d %h:%M:%S"; }
		Get_Pic_Timestamp() { date +"%Y%m%d_%H%M%S"; }
		Get_Output_Dir() { echo "$HOME/picture/temporary"; }
		Make_Output_Dir() { mkdir -p "$(Get_Output_Dir)"; }
		Get_Filename() { echo "$(Get_Output_Dir)/capture_$(Get_Pic_Timestamp)"; }
		Capture_Picture() { fswebcam -d /dev/video0 -r 1280x720 --no-banner "$FILENAME"; }
		echo -e "[*] Checking Requirements..."
		Card=$(Get_Card)
		Card_Mode=$(Get_Current_Card_Mode)
		Public_Ip=$(Get_Public_Ip)
		MAC=$(Get_Mac_Address)
		Loc=$(Get_Loc)
		if [[ -z "$Card" ]]; then echo "[!] No Card";
		else echo "[+] Card: $Card"; fi
		
		if [[ -z "$Card_Mode" ]]; then echo "[!] No Card Mode";
		else echo "[+] Card Mode: $Card_Mode"; fi

		if [[ -z "$Public_Ip" ]]; then echo "[!] No Public Ip";
		else echo "[+] Public Ip: $Public_Ip"; fi

		if [[ -z "$MAC" ]]; then echo "[!] No Mac Address";
		else echo "[+] Mac Address: $MAC"; fi

		if [[ -z "$Loc" ]]; then echo "[!] No Location";
		else echo "[+] Location: $Loc"; fi

		echo "[+] Time Stamp: $(Get_Timestamp)"
	}
	Check_Internet_Connection
}

CHECK_REQUIREMENTS
