# Define colors if not already defined globally
: "${RED:=\033[0;31m}"
: "${YELLOW:=\033[1;33m}"
: "${GREEN:=\033[0;32m}"
: "${NC:=\033[0m}" # No Color

get_info() {
    local card
    local card_info
    local mode
    local addr
    local prop="$1"

    # Detect primary wireless interface
    card=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)

    if [[ -z "$card" ]]; then
        echo -e "${RED}[!] No wireless interface found.${NC}"
        return 1
    fi

    card_info=$(iw dev "$card" info 2>/dev/null)
    
    if [[ -z "$card_info" ]]; then
        echo -e "${RED}[!] Could not retrieve info for $card.${NC}"
        return 1
    fi

    mode=$(echo "$card_info" | awk '/type/ {print $2}')
    addr=$(echo "$card_info" | awk '/addr/ {print $2}')

    # Helper function for usage (defined locally via a subshell or just inline)
    _show_usage() {
        echo -e "${YELLOW}[*] Usage: get_info <option>${NC}"
        echo -e "${YELLOW}[*] Options:${NC}"
        echo -e "  ${GREEN}card${NC}  : Show interface name"
        echo -e "  ${GREEN}mode${NC}  : Show current mode (managed/monitor)"
        echo -e "  ${GREEN}addr${NC}  : Show MAC address"
        echo -e "  ${GREEN}help${NC}  : Show this help message"
    }

    # If an argument is provided, handle specific requests
    if [[ -n "$prop" ]]; then
        case "$prop" in
            card)
                echo "$card"
                ;;
            mode)
                echo "$mode"  # Fixed: was echoing $addr
                ;;
            addr)
                echo "$addr"
                ;;
            help)
                _show_usage
                ;;
            *)
                echo -e "${RED}[!] Unknown option: $prop${NC}"
                _show_usage
                return 1
                ;;
        esac
        return 0 # Success
    fi

    # Default: Show all info
    echo -e "${YELLOW}[*] Card Name\t\t:${GREEN} $card${NC}"
    echo -e "${YELLOW}[*] Current Mode\t:${GREEN} $mode${NC}"
    echo -e "${YELLOW}[*] MAC Address\t\t:${GREEN} $addr${NC}"
    
    return 0
}
