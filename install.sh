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

# Prevent shell tracing to reduce clutter
set +x

print_header() {
    clear
    echo -e "${CYAN}TurboAsusSec Installer v${VERSION}${NC}"
    echo ""
}

download_script() {
    script=$1
    curl -sSLf "$REPO_URL/scripts/$script" -o "$SCRIPT_DIR/$script" || {
        echo -e "${RED}Failed to download $script${NC}"
    }
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
        download_script "$script"
    done

    # Create symlink for CLI access
    ln -sf "$SCRIPT_DIR/tcds.sh" /jffs/scripts/tcds

    # Backup and add alias
    cp /jffs/configs/profile.add /jffs/configs/profile.add.bak 2>/dev/null
    if ! grep -q 'alias tcds=' /jffs/configs/profile.add 2>/dev/null; then
        echo 'alias tcds="sh /jffs/scripts/tcds.sh"' >> /jffs/configs/profile.add
    fi

    # Source profile and confirm
    . /jffs/configs/profile.add 2>/dev/null
    echo -e "${GREEN}Alias 'tcds' is active. You can now run 'tcds' from any shell.${NC}"
}

uninstall_scripts() {
    echo -n "WARNING: This will uninstall TurboAsusSec. Type 'yes' to continue: "
    read confirm
    if [ "$confirm" = "yes" ]; then
        cp /jffs/configs/profile.add /jffs/configs/profile.add.bak 2>/dev/null
        sed -i '/alias tcds=/d' /jffs/configs/profile.add 2>/dev/null
        if [ -L /jffs/scripts/tcds ]; then
            rm -f /jffs/scripts/tcds
            echo "Symlink /jffs/scripts/tcds removed"
        fi
        rm -rf "$INSTALL_DIR"
        echo "Uninstall complete"
    else
        echo "Uninstall cancelled"
    fi
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
        3|uninstall) uninstall_scripts;;
        0|e|exit) exit 0;;
        *) echo "Invalid selection"; main_menu;;
    esac
}

main_menu
