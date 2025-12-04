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
    echo -ne "${CYAN}Enter choice (or 'e' to exit): ${NC}"
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
    
    # Check for Skynet or Diversion
    local has_integration=0
    if [ -f "/jffs/scripts/firewall" ]; then
        echo -e "${GREEN}✓ Skynet detected${NC}"
        has_integration=1
    fi
    if [ -d "/opt/share/diversion" ]; then
        echo -e "${GREEN}✓ Diversion detected${NC}"
        has_integration=1
    fi
    
    if [ "$has_integration" -eq 0 ]; then
        echo -e "${RED}Warning: Neither Skynet nor Diversion detected${NC}"
        echo -e "${YELLOW}Install at least one for full functionality${NC}"
        echo ""
        echo -ne "Continue anyway? (y/n): "
        read continue_choice
        [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ] && return 1
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
    
    # POSIX-compliant script list
    local scripts="tcds.sh tcds-core.sh tcds-aiprotect.sh tcds-diagnostics.sh tcds-whitelist.sh tcds-service.sh"
    local updated_count=0
    local failed_count=0
    
    for script in $scripts; do
        echo -n "  $script... "
        
        # Check if file exists and get its hash for comparison
        local old_hash=""
        if [ -f "$SCRIPT_DIR/$script" ]; then
            old_hash=$(md5sum "$SCRIPT_DIR/$script" 2>/dev/null | cut -d' ' -f1)
        fi
        
        # Download
        if curl -sSLf "$REPO_URL/scripts/$script" -o "$SCRIPT_DIR/$script.tmp" 2>/dev/null; then
            chmod 755 "$SCRIPT_DIR/$script.tmp"
            mv "$SCRIPT_DIR/$script.tmp" "$SCRIPT_DIR/$script"
            
            # Check if updated
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
            
            # Try wget as fallback
            echo -n "  Trying wget... "
            if wget -q "$REPO_URL/scripts/$script" -O "$SCRIPT_DIR/$script" 2>/dev/null; then
                chmod 755 "$SCRIPT_DIR/$script"
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗ failed${NC}"
                rm -f "$SCRIPT_DIR/$script.tmp"
            fi
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
    echo -e "${GREEN}✓ Symlink created${NC}"
    
    # Setup alias in profile.add
    if [ -f /jffs/configs/profile.add ]; then
        # Backup first
        cp /jffs/configs/profile.add /jffs/configs/profile.add.bak 2>/dev/null
        
        # Add alias if not present
        if ! grep -q 'alias tcds=' /jffs/configs/profile.add 2>/dev/null; then
            echo 'alias tcds="sh /jffs/scripts/tcds"  # TurboAsusSec' >> /jffs/configs/profile.add
            echo -e "${GREEN}✓ Alias added to profile${NC}"
        else
            echo -e "${CYAN}ℹ Alias already exists${NC}"
        fi
        
        # Source the profile for current session
        . /jffs/configs/profile.add 2>/dev/null
    else
        # Create profile.add if it doesn't exist
        echo 'alias tcds="sh /jffs/scripts/tcds"  # TurboAsusSec' > /jffs/configs/profile.add
        echo -e "${GREEN}✓ Created profile.add with alias${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✓ You can now type 'tcds' from anywhere!${NC}"
    echo ""
}

setup_service_event() {
    echo -e "${YELLOW}Setting up service event handler...${NC}"
    
    # Create or update service-event script
    if [ ! -f /jffs/scripts/service-event ]; then
        cat > /jffs/scripts/service-event << 'SERVICEEVENT'
#!/bin/sh
SERVICEEVENT
        chmod 755 /jffs/scripts/service-event
    fi
    
    # Add TurboAsusSec hook if not present
    if ! grep -q "### TurboAsusSec" /jffs/scripts/service-event; then
        cat >> /jffs/scripts/service-event << 'SERVICECALL'

### TurboAsusSec start
/jffs/addons/tcds/scripts/tcds-service.sh $*
### TurboAsusSec end
SERVICECALL
        echo -e "${GREEN}✓ Service event configured${NC}"
    else
        echo -e "${CYAN}ℹ Service event already configured${NC}"
    fi
    echo ""
}

initialize_settings() {
    echo -e "${YELLOW}Initializing settings...${NC}"
    
    if [ -f /usr/sbin/helper.sh ]; then
        . /usr/sbin/helper.sh
        
        am_settings_set tcds_version "$VERSION" 2>/dev/null
        am_settings_set tcds_skynet_sync "enabled" 2>/dev/null
        am_settings_set tcds_diversion_sync "enabled" 2>/dev/null
        am_settings_set tcds_aiprotect_enabled "enabled" 2>/dev/null
        am_settings_set tcds_cache_ttl "600" 2>/dev/null
        
        echo -e "${GREEN}✓ Settings initialized${NC}"
    else
        echo -e "${YELLOW}⚠ Helper not available, skipping settings${NC}"
    fi
    echo ""
}

do_install() {
    print_header
    echo -e "${CYAN}Starting installation...${NC}"
    echo ""
    
    check_requirements || return 1
    create_directories
    download_scripts 0 || {
        echo -e "${RED}Installation failed during download${NC}"
        echo ""
        echo "Possible causes:"
        echo "  • Network connectivity issues"
        echo "  • GitHub not accessible"
        echo ""
        return 1
    }
    setup_alias
    setup_service_event
    initialize_settings
    
    print_header
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Installation Complete!                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Access TurboAsusSec:${NC}"
    echo -e "  • Type: ${GREEN}tcds${NC} (from anywhere)"
    echo -e "  • Or: ${GREEN}/jffs/scripts/tcds${NC}"
    echo ""
    echo -e "${CYAN}Quick Start:${NC}"
    echo -e "  ${GREEN}tcds${NC}              - Interactive menu"
    echo -e "  ${GREEN}tcds diagnostics${NC}  - Run diagnostics"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo "  https://github.com/CutterSol/TurboAsusSec"
    echo ""
    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read
}

do_update() {
    print_header
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}TurboAsusSec not installed${NC}"
        echo ""
        echo "Run option 1 to install first"
        echo ""
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read
        return 1
    fi
    
    echo -e "${CYAN}Updating TurboAsusSec...${NC}"
    echo ""
    
    echo "Backing up current installation..."
    cp -r "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null
    
    echo ""
    download_scripts 1 || {
        echo -e "${RED}Update failed${NC}"
        echo ""
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read
        return 1
    }
    
    # Ensure alias is still set
    setup_alias
    
    echo -e "${GREEN}✓ Update complete!${NC}"
    echo ""
    echo "Run 'tcds' to use the updated version"
    echo ""
    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read
}

do_uninstall() {
    print_header
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              TurboAsusSec Uninstaller                        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This will remove TurboAsusSec from your router${NC}"
    echo -e "${YELLOW}Custom lists will be backed up to /tmp/tcds_backup${NC}"
    echo ""
    echo -ne "Type 'yes' to confirm uninstall: "
    read confirm
    
    if [ "$confirm" != "yes" ]; then
        echo ""
        echo "Uninstall cancelled"
        echo ""
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read
        return 0
    fi
    
    echo ""
    echo "Backing up custom lists..."
    mkdir -p /tmp/tcds_backup
    cp "$INSTALL_DIR/custom_whitelist.txt" /tmp/tcds_backup/ 2>/dev/null
    cp "$INSTALL_DIR/custom_blacklist.txt" /tmp/tcds_backup/ 2>/dev/null
    
    echo "Removing alias..."
    if [ -f /jffs/configs/profile.add ]; then
        cp /jffs/configs/profile.add /jffs/configs/profile.add.bak 2>/dev/null
        sed -i '/# TurboAsusSec/d' /jffs/configs/profile.add 2>/dev/null
        sed -i '/alias tcds=/d' /jffs/configs/profile.add 2>/dev/null
    fi
    
    echo "Removing symlink..."
    rm -f /jffs/scripts/tcds
    
    echo "Removing service-event hook..."
    if [ -f /jffs/scripts/service-event ]; then
        sed -i '/### TurboAsusSec start/,/### TurboAsusSec end/d' /jffs/scripts/service-event 2>/dev/null
    fi
    
    echo "Removing files..."
    rm -rf "$INSTALL_DIR"
    rm -rf /tmp/tcds
    
    echo ""
    echo -e "${GREEN}✓ TurboAsusSec uninstalled${NC}"
    echo ""
    echo "Backup location: /tmp/tcds_backup"
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
            1)
                do_install
                ;;
            2)
                do_update
                ;;
            3)
                do_uninstall
                ;;
            0|e|E|exit)
                clear
                echo "Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo -e "${RED}Invalid choice${NC}"
                sleep 2
                ;;
        esac
    done
}

main
