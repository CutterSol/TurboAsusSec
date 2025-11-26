#!/bin/sh
#####################################################################################################
# TurboChargeDivSky Installer
# One-command installation for ASUS Merlin routers
#
# Installation:
# curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/TurboChargeDivSky/master/install.sh | sh
#####################################################################################################

VERSION="1.2.0"
REPO_URL="https://raw.githubusercontent.com/YOUR_USERNAME/TurboChargeDivSky/master"
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
    echo -e "${CYAN}║          TurboChargeDivSky Installer v${VERSION}              ║${NC}"
    echo -e "${CYAN}║   Unified Security Management for ASUS Merlin                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    # Check for Merlin firmware
    if ! grep -q "asuswrt-merlin" /etc/issue 2>/dev/null; then
        if [ ! -f "/usr/sbin/helper.sh" ]; then
            echo -e "${RED}Error: This script requires ASUS Merlin firmware${NC}"
            exit 1
        fi
    fi
    
    # Check for addon support
    if ! nvram get rc_support 2>/dev/null | grep -q "am_addons"; then
        echo -e "${YELLOW}Warning: Merlin Addon API not detected${NC}"
        echo -e "${YELLOW}Web UI integration may not work (requires 384.15+)${NC}"
    fi
    
    # Check for Skynet or Diversion
    local has_integration=0
    [ -f "/jffs/scripts/firewall" ] && has_integration=1
    [ -d "/opt/share/diversion" ] && has_integration=1
    
    if [ "$has_integration" -eq 0 ]; then
        echo -e "${RED}Warning: Neither Skynet nor Diversion detected${NC}"
        echo -e "${YELLOW}Install at least one for full functionality${NC}"
        echo ""
        echo -ne "Continue anyway? (y/n): "
        read continue_choice
        [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ] && exit 1
    fi
    
    echo -e "${GREEN}✓ Requirements check passed${NC}"
    echo ""
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
    echo -e "${YELLOW}Downloading scripts...${NC}"
    
    local scripts=(
        "tcds.sh"
        "tcds-core.sh"
        "tcds-whitelist.sh"
        "tcds-aiprotect.sh"
        "tcds-threat-db.sh"
        "tcds-diagnostics.sh"
        "tcds-skynet.sh"
        "tcds-diversion.sh"
        "tcds-service.sh"
    )
    
    for script in "${scripts[@]}"; do
        echo "  Downloading $script..."
        if curl -sSLf "$REPO_URL/scripts/$script" -o "$SCRIPT_DIR/$script"; then
            chmod 755 "$SCRIPT_DIR/$script"
            echo -e "  ${GREEN}✓${NC} $script"
        else
            echo -e "  ${RED}✗${NC} Failed to download $script"
            return 1
        fi
    done
    
    # Create symlink for easy access
    ln -sf "$SCRIPT_DIR/tcds.sh" /jffs/scripts/tcds
    
    echo -e "${GREEN}✓ All scripts downloaded${NC}"
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
    
    # Add TurboChargeDivSky hook if not present
    if ! grep -q "### TurboChargeDivSky" /jffs/scripts/service-event; then
        cat >> /jffs/scripts/service-event << 'SERVICECALL'

### TurboChargeDivSky start
/jffs/addons/tcds/scripts/tcds-service.sh $*
### TurboChargeDivSky end
SERVICECALL
    fi
    
    echo -e "${GREEN}✓ Service event configured${NC}"
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

show_completion() {
    print_header
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Installation Complete!                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Access TurboChargeDivSky:${NC}"
    echo -e "  • CLI: ${GREEN}tcds${NC} or ${GREEN}/jffs/scripts/tcds${NC}"
    echo -e "  • Full path: /jffs/addons/tcds/scripts/tcds.sh"
    echo ""
    echo -e "${CYAN}Quick Start:${NC}"
    echo -e "  ${GREEN}tcds${NC}              - Interactive menu"
    echo -e "  ${GREEN}tcds overview${NC}     - System overview"
    echo -e "  ${GREEN}tcds diagnostics${NC}  - Run diagnostics"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Run 'tcds diagnostics' to verify integration"
    echo "  2. Explore the menu options"
    echo "  3. Check logs at: $INSTALL_DIR/logs/tcds.log"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo "  https://github.com/YOUR_USERNAME/TurboChargeDivSky"
    echo ""
    echo -e "${YELLOW}Note: Web UI integration coming in next update${NC}"
    echo ""
}

uninstall() {
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              TurboChargeDivSky Uninstaller                   ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This will remove TurboChargeDivSky from your router${NC}"
    echo -e "${YELLOW}Custom lists will be backed up to /tmp/tcds_backup${NC}"
    echo ""
    echo -ne "Are you sure? (yes/no): "
    read confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Uninstall cancelled"
        exit 0
    fi
    
    echo ""
    echo "Backing up custom lists..."
    mkdir -p /tmp/tcds_backup
    cp "$INSTALL_DIR/custom_whitelist.txt" /tmp/tcds_backup/ 2>/dev/null
    cp "$INSTALL_DIR/custom_blacklist.txt" /tmp/tcds_backup/ 2>/dev/null
    
    echo "Removing service-event hook..."
    sed -i '/### TurboChargeDivSky start/,/### TurboChargeDivSky end/d' /jffs/scripts/service-event 2>/dev/null
    
    echo "Removing files..."
    rm -rf "$INSTALL_DIR"
    rm -f /jffs/scripts/tcds
    rm -rf /tmp/tcds
    
    echo ""
    echo -e "${GREEN}✓ TurboChargeDivSky uninstalled${NC}"
    echo ""
    echo "Backup location: /tmp/tcds_backup"
    echo ""
}

update() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              TurboChargeDivSky Updater                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}TurboChargeDivSky not installed${NC}"
        echo "Run installer without arguments to install"
        exit 1
    fi
    
    echo "Backing up current installation..."
    cp -r "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    
    echo ""
    download_scripts
    
    echo -e "${GREEN}✓ Update complete!${NC}"
    echo ""
    echo "Run 'tcds' to start using the updated version"
    echo ""
}

# Main installation flow
main() {
    case "$1" in
        uninstall)
            uninstall
            ;;
        update)
            update
            ;;
        *)
            print_header
            echo -e "${CYAN}Starting installation...${NC}"
            echo ""
            
            check_requirements
            create_directories
            download_scripts || {
                echo -e "${RED}Installation failed during download${NC}"
                exit 1
            }
            setup_service_event
            initialize_settings
            
            show_completion
            ;;
    esac
}

main "$@"
