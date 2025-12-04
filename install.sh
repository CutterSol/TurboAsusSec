#!/bin/sh
#####################################################################################################
# TurboAsusSec Installer v1.2.1
# Interactive installation for ASUS Merlin routers
#
# Usage:
# curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main/install.sh -o /tmp/tcds-install.sh && sh /tmp/tcds-install.sh
#####################################################################################################

VERSION="1.2.1"
REPO_URL="https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main"
INSTALL_DIR="/jffs/addons/tcds"
SCRIPT_DIR="$INSTALL_DIR/scripts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          TurboAsusSec Installer v${VERSION}                   ║${NC}"
    echo -e "${CYAN}║   Unified Security Management for ASUS Merlin                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    print_header
    echo -e "${GREEN}Installation Menu:${NC}"
    echo ""
    echo "  1) Install TurboAsusSec"
    echo "  2) Update TurboAsusSec"
    echo "  3) Uninstall TurboAsusSec"
    echo "  0) Exit"
    echo ""
    echo -ne "${CYAN}Enter choice: ${NC}"
}

check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    # Check for Merlin firmware
    if ! grep -q "asuswrt-merlin" /etc/issue 2>/dev/null; then
        if [ ! -f "/usr/sbin/helper.sh" ]; then
            echo -e "${RED}Error: This script requires ASUS Merlin firmware${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✓ Requirements check passed${NC}"
    echo ""
    return 0
}

create_directories() {
    echo -e "${YELLOW}Creating directory structure...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$SCRIPT_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/webui"
    mkdir -p "/tmp/tcds"
    
    # Create empty custom lists
    touch "$INSTALL_DIR/custom_whitelist.txt"
    touch "$INSTALL_DIR/custom_blacklist.txt"
    
    echo -e "${GREEN}✓ Directories created${NC}"
    echo ""
}

download_scripts() {
    local is_update="${1:-0}"
    echo -e "${YELLOW}Downloading scripts...${NC}"
    
    local scripts="tcds.sh tcds-core.sh tcds-aiprotect.sh tcds-diagnostics.sh tcds-whitelist.sh tcds-service.sh"
    local updated_count=0
    local failed_count=0
    
    for script in $scripts; do
        echo -n "  $script... "
        
        local old_hash=""
        if [ -f "$SCRIPT_DIR/$script" ]; then
            old_hash=$(md5sum "$SCRIPT_DIR/$script" 2>/dev/null | cut -d' ' -f1)
        fi
        
        if curl -sSLf "$REPO_URL/scripts/$script" -o "$SCRIPT_DIR/$script.tmp" 2>/dev/null; then
            chmod 755 "$SCRIPT_DIR/$script.tmp"
            mv "$SCRIPT_DIR/$script.tmp" "$SCRIPT_DIR/$script"
            
            if [ "$is_update" -eq 1 ] && [ -n "$old_hash" ]; then
                local new_hash=$(md5sum "$SCRIPT_DIR/$script" 2>/dev/null | cut -d' ' -f1)
                if [ "$old_hash" = "$new_hash" ]; then
                    echo -e "${CYAN}unchanged${NC}"
                else
                    echo -e "${GREEN}✓ updated${NC}"
                    updated_count=$((updated_count + 1))
                fi
            else
                echo -e "${GREEN}✓${NC}"
            fi
        else
            echo -e "${RED}✗ failed${NC}"
            failed_count=$((failed_count + 1))
        fi
    done
    
    echo ""
    if [ "$is_update" -eq 1 ]; then
        if [ "$updated_count" -gt 0 ]; then
            echo -e "${GREEN}✓ Updated $updated_count file(s)${NC}"
        else
            echo -e "${CYAN}ℹ All files are up to date${NC}"
        fi
    fi
    
    if [ "$failed_count" -gt 0 ]; then
        echo -e "${RED}⚠ Failed to download $failed_count file(s)${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ All scripts downloaded${NC}"
    echo ""
    return 0
}

setup_alias() {
    echo -e "${YELLOW}Setting up 'tcds' command...${NC}"
    
    # Create symlink
    ln -sf "$SCRIPT_DIR/tcds.sh" /jffs/scripts/tcds
    chmod +x "$SCRIPT_DIR/tcds.sh"
    echo -e "${GREEN}✓ Symlink created${NC}"
    
    # Setup alias in profile.add
    if [ -f /jffs/configs/profile.add ]; then
        cp /jffs/configs/profile.add /jffs/configs/profile.add.bak 2>/dev/null
        if ! grep -q 'alias tcds=' /jffs/configs/profile.add 2>/dev/null; then
            echo 'alias tcds="sh /jffs/scripts/tcds"  # TurboAsusSec' >> /jffs/configs/profile.add
            echo -e "${GREEN}✓ Alias added to profile${NC}"
        fi
    else
        echo 'alias tcds="sh /jffs/scripts/tcds"  # TurboAsusSec' > /jffs/configs/profile.add
        echo -e "${GREEN}✓ Created profile.add with alias${NC}"
    fi
    
    # Ensure /jffs/scripts is in PATH
    if ! echo "$PATH" | grep -q "/jffs/scripts"; then
        export PATH="/jffs/scripts:$PATH"
        if ! grep -q '/jffs/scripts' /jffs/configs/profile.add 2>/dev/null; then
            echo 'export PATH="/jffs/scripts:$PATH"' >> /jffs/configs/profile.add
        fi
        echo -e "${GREEN}✓ /jffs/scripts added to PATH${NC}"
    fi
    
    # Source the profile for current session
    . /jffs/configs/profile.add 2>/dev/null
    
    echo ""
}

do_install() {
    print_header
    echo -e "${CYAN}Starting installation...${NC}"
    echo ""
    
    check_requirements || return 1
    create_directories
    download_scripts 0 || return 1
    setup_alias
    
    print_header
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read
}

do_update() {
    print_header
    echo -e "${CYAN}Updating TurboAsusSec...${NC}"
    echo ""
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}TurboAsusSec not installed${NC}"
        echo ""
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read
        return 1
    fi
    
    download_scripts 1 || return 1
    setup_alias
    
    echo -e "${GREEN}Update complete!${NC}"
    echo ""
    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read
}

do_uninstall() {
    print_header
    echo -e "${RED}Uninstalling TurboAsusSec...${NC}"
    echo ""
    echo -ne "Type 'yes' to confirm uninstall: "
    read confirm
    if [ "$confirm" != "yes" ]; then
        echo "Uninstall cancelled"
        return 0
    fi
    
    # Remove alias and PATH entries
    if [ -f /jffs/configs/profile.add ]; then
        cp /jffs/configs/profile.add /jffs/configs/profile.add.bak 2>/dev/null
        sed -i '/# TurboAsusSec/d' /jffs/configs/profile.add 2>/dev/null
        sed -i '/alias tcds=/d' /jffs/configs/profile.add 2>/dev/null
        sed -i '/\/jffs\/scripts/d' /jffs/configs/profile.add 2>/dev/null
    fi
    
    # Remove symlink
    rm -f /jffs/scripts/tcds
    
    # Remove installation
    rm -rf "$INSTALL_DIR"
    rm -rf /tmp/tcds
    
    echo -e "${GREEN}TurboAsusSec uninstalled${NC}"
    echo ""
    echo -ne "${CYAN}Press Enter to exit...${NC}"
    read
    exit 0
}

# Main menu loop
main() {
    while true; do
        show_menu
        read choice
        case "$choice" in
            1) do_install ;;
            2) do_update ;;
            3) do_uninstall ;;
            0) clear; echo "Goodbye!"; exit 0 ;;
            *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
        esac
    done
}

main
