#!/bin/sh
#####################################################################################################
# TurboAsusSec Installer v1.2.1
# One-command installation for ASUS Merlin routers
# Works with curl | sh
#####################################################################################################

VERSION="1.2.1"
REPO_URL="https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main"
INSTALL_DIR="/jffs/addons/tcds"
SCRIPT_DIR="$INSTALL_DIR/scripts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${CYAN}TurboAsusSec Installer v${VERSION}${NC}"
    echo ""
}

check_downloaders() {
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo -e "${RED}Error: curl or wget is required${NC}"
        echo "Please install Entware curl/wget first."
        exit 1
    fi
}

download_script() {
    script=$1
    if command -v curl >/dev/null 2>&1; then
        curl -sSLf "$REPO_URL/scripts/$script" -o "$SCRIPT_DIR/$script"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL/scripts/$script" -O "$SCRIPT_DIR/$script"
    fi
    chmod 755 "$SCRIPT_DIR/$script"
}

create_directories() {
    mkdir -p "$SCRIPT_DIR" "$INSTALL_DIR/logs" "$INSTALL_DIR/webui" "/tmp/tcds"
    touch "$INSTALL_DIR/custom_whitelist.txt" "$INSTALL_DIR/custom_blacklist.txt"
}

install_scripts() {
    echo -e "${YELLOW}Downloading scripts...${NC}"
    for script in tcds.sh tcds-core.sh tcds-aiprotect.sh tcds-diagnostics.sh tcds-whitelist.sh tcds-service.sh; do
        echo " - $script"
        download_script "$script" || echo "Failed to download $script"
    done
    ln -sf "$SCRIPT_DIR/tcds.sh" /jffs/scripts/tcds
}

main_menu() {
    print_header
    echo "1) Install"
    echo "2) Update"
    echo "3) Uninstall"
    echo "0) Exit"
    echo -n "Select: "
    read choice
    case "$choice" in
        1|install) create_directories; install_scripts; echo "Installation complete";;
        2|update) install_scripts; echo "Update complete";;
        3|uninstall)
            echo -n "Type 'yes' to uninstall: "
            read confirm
            [ "$confirm" = "yes" ] && rm -rf "$INSTALL_DIR" /jffs/scripts/tcds && echo "Uninstalled" || echo "Cancelled";;
        0|e|exit) exit 0;;
        *) echo "Invalid selection"; main_menu;;
    esac
}

check_downloaders
main_menu
