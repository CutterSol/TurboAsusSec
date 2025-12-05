#!/bin/sh
#####################################################################################################
# TurboAsusSec - Main Menu Script
# Version: 1.2.0
# Orchestrates all modules and provides main menu interface
#####################################################################################################

# Determine script directory - handle symlinks and aliases
# Always use the absolute path since we know where it's installed
SCRIPT_DIR="/jffs/addons/tcds/scripts"

# Verify core module exists
if [ ! -f "$SCRIPT_DIR/tcds-core.sh" ]; then
    # Try to find it relative to script location as fallback
    if [ -L "$0" ]; then
        SCRIPT_PATH=$(readlink "$0" 2>/dev/null)
        [ -n "$SCRIPT_PATH" ] && SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    else
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    fi
fi

# Source core functions
if [ -f "$SCRIPT_DIR/tcds-core.sh" ]; then
    . "$SCRIPT_DIR/tcds-core.sh"
else
    echo "ERROR: Core module not found"
    echo "Expected location: $SCRIPT_DIR/tcds-core.sh"
    echo "Try reinstalling: curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main/install.sh -o /tmp/tcds-install.sh && sh /tmp/tcds-install.sh"
    exit 1
fi

#####################################################################################################
# MODULE LOADING
#####################################################################################################

# Load optional modules
load_module "tcds-aiprotect.sh"
load_module "tcds-diagnostics.sh"
load_module "tcds-whitelist.sh"

#####################################################################################################
# OVERVIEW
#####################################################################################################

show_overview() {
    print_header "TurboAsusSec Overview"
    
    if skynet_installed; then
        print_success "Skynet: Installed"
        local skynet_whitelist_count=$(ipset list Skynet-Whitelist 2>/dev/null | grep -c "^[0-9]")
        local skynet_blacklist_count=$(ipset list Skynet-Blacklist 2>/dev/null | grep -c "^[0-9]")
        echo "  Whitelist entries: $skynet_whitelist_count"
        echo "  Blacklist entries: $skynet_blacklist_count"
    else
        print_warning "Skynet: Not installed"
    fi
    echo ""
    
    if diversion_installed; then
        print_success "Diversion: Installed"
        local div_allowlist_count=$(wc -l < "$DIVERSION_PATH/list/allowlist" 2>/dev/null || echo 0)
        local div_denylist_count=$(wc -l < "$DIVERSION_PATH/list/denylist" 2>/dev/null || echo 0)
        echo "  Allowlist entries: $div_allowlist_count"
        echo "  Denylist entries: $div_denylist_count"
    else
        print_warning "Diversion: Not installed"
    fi
    echo ""
    
    if aiprotect_available; then
        print_success "AIProtect: Database available"
        if sqlite_available; then
            local aiprotect_events=$(sqlite3 "$AIPROTECT_DB" "SELECT COUNT(*) FROM monitor;" 2>/dev/null || echo 0)
            echo "  Total events logged: $aiprotect_events"
        else
            echo "  (sqlite3 not available for queries)"
        fi
    else
        print_warning "AIProtect: Database not found"
    fi
    echo ""
    
    local custom_wl=$(wc -l < "$INSTALL_DIR/custom_whitelist.txt" 2>/dev/null || echo 0)
    local custom_bl=$(wc -l < "$INSTALL_DIR/custom_blacklist.txt" 2>/dev/null || echo 0)
    print_info "Custom Lists:"
    echo "  Whitelist entries: $custom_wl"
    echo "  Blacklist entries: $custom_bl"
    echo ""
}

#####################################################################################################
# SKYNET LOG VIEWING
#####################################################################################################

show_skynet_logs() {
    print_header "Recent Skynet Blocks"
    
    if ! skynet_installed; then
        print_error "Skynet not installed"
        return 1
    fi
    
    # FIX: Replaced the original 'get_skynet_path' logic with a more robust 'find' command
    # to reliably locate the log file on any mounted USB drive.
    local log_file=$(find /tmp/mnt -name "skynet.log" 2>/dev/null | head -n 1)
    
    # Fallback for non-USB installs if not found on a mount
    if [ -z "$log_file" ] && [ -f "/jffs/skynet/skynet.log" ]; then
        log_file="/jffs/skynet/skynet.log"
    fi
    
    if [ ! -f "$log_file" ]; then
        print_warning "Skynet log file not found"
        print_info "Checked common locations like /tmp/mnt/*/skynet/skynet.log"
        return 1
    fi
    
    echo -ne "${CYAN}How many recent blocks to show? (default: 20): ${NC}"
    read limit
    limit="${limit:-20}"
    
    echo ""
    echo -e "${YELLOW}Last $limit Skynet blocks from $log_file:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    grep "BLOCKED" "$log_file" | tail -n "$limit" || {
        print_warning "No recent 'BLOCKED' entries found in log"
    }
}

#####################################################################################################
# WHITELIST/BLOCKLIST OPERATIONS
#####################################################################################################

show_merged_whitelist() {
    print_header "Merged Whitelist View"
    
    local cache_file="$CACHE_DIR/merged_whitelist.cache"
    
    if ! check_cache_valid "$cache_file"; then
        show_progress "Building merged whitelist"
        
        {
            # Diversion allowlist
            if [ -f "$DIVERSION_PATH/list/allowlist" ]; then
                awk '{print $1 "\tDiversion\tDomain"}' "$DIVERSION_PATH/list/allowlist" 2>/dev/null
            fi
            
            # Skynet whitelist - check if ipset command works
            # FIX: Replaced 'command -v ipset' with a direct check for the executable file.
            # This is more reliable on embedded systems and fixes the bug where Skynet entries were not showing.
            if [ -x "/usr/sbin/ipset" ]; then
                # Try to list Skynet IPSets
                local skynet_sets=$(/usr/sbin/ipset list -n 2>/dev/null | grep -i skynet | grep -i white)
                if [ -n "$skynet_sets" ]; then
                    echo "$skynet_sets" | while read setname; do
                        /usr/sbin/ipset list "$setname" 2>/dev/null | grep -E "^[0-9]" | awk -v set="$setname" '{
                            # Detect type based on entry format
                            if ($1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$/) {
                                type="CIDR"
                            } else if ($1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
                                type="IP"
                            } else {
                                type="Entry"
                            }
                            print $1 "\tSkynet\t" type
                        }'
                    done
                fi
            fi
            
            # Custom entries
            if [ -f "$INSTALL_DIR/custom_whitelist.txt" ]; then
                awk '{print $1 "\tCustom\t-"}' "$INSTALL_DIR/custom_whitelist.txt" 2>/dev/null
            fi
        } | sort -u > "$cache_file"
        
        update_cache_time "$cache_file"
        hide_progress
    fi
    
    local count=$(wc -l < "$cache_file" 2>/dev/null || echo 0)
    echo "Total entries: $count"
    echo ""
    
    if [ "$count" -gt 0 ]; then
        echo -e "${YELLOW}Entry\t\t\tSource\t\tType${NC}"
        echo "─────────────────────────────────────────────────────────────"
        
        # Show ALL entries, with pagination if over 100
        if [ "$count" -gt 100 ]; then
            echo -e "${CYAN}Showing all $count entries (press 'q' to quit pager)${NC}"
            column -t < "$cache_file" | less
        else
            column -t < "$cache_file"
        fi
    else
        print_warning "No whitelist entries found"
    fi
}

add_to_whitelist_interactive() {
    print_header "Add to Whitelist"
    
    echo -ne "${CYAN}Enter IP or domain to whitelist: ${NC}"
    read entry
    
    if [ -z "$entry" ]; then
        print_error "No entry provided"
        return 1
    fi
    
    echo ""
    echo "Where should this be added?"
    echo "  1) Skynet only"
    echo "  2) Diversion only"
    echo "  3) Both Skynet and Diversion"
    echo "  4) Custom list only"
    echo -ne "${CYAN}Choice (1-4): ${NC}"
    read choice
    
    case "$choice" in
        1) target="skynet" ;;
        2) target="diversion" ;;
        3) target="both" ;;
        4) target="custom" ;;
        *) print_error "Invalid choice"; return 1 ;;
    esac
    
    echo ""
    
    case "$target" in
        skynet)
            if skynet_installed; then
                "$SKYNET_CMD" whitelist ip "$entry" comment "Added by TurboAsusSec" >/dev/null 2>&1
                print_success "Added to Skynet whitelist"
            else
                print_error "Skynet not installed"
            fi
            ;;
        diversion)
            if diversion_installed; then
                safe_append "$DIVERSION_PATH/list/allowlist" "$entry"
                print_success "Added to Diversion allowlist"
            else
                print_error "Diversion not installed"
            fi
            ;;
        both)
            local added=0
            if skynet_installed; then
                "$SKYNET_CMD" whitelist ip "$entry" comment "Added by TurboAsusSec" >/dev/null 2>&1
                print_success "Added to Skynet whitelist"
                added=1
            fi
            if diversion_installed; then
                safe_append "$DIVERSION_PATH/list/allowlist" "$entry"
                print_success "Added to Diversion allowlist"
                added=1
            fi
            [ "$added" -eq 0 ] && print_error "Neither Skynet nor Diversion available"
            ;;
        custom)
            safe_append "$INSTALL_DIR/custom_whitelist.txt" "$entry"
            print_success "Added to custom whitelist"
            ;;
    esac
    
    # Clear cache
    rm -f "$CACHE_DIR/merged_whitelist.cache"
    log_info "Added $entry to $target whitelist"
}

# NEW: Added a function to handle running the update script.
run_update() {
    print_header "Update Script"
    local install_script_path="/jffs/addons/tcds/install.sh"
    
    if [ -f "$install_script_path" ]; then
        print_info "Running the installer to check for updates..."
        echo ""
        sh "$install_script_path"
    else
        print_error "Update failed: install.sh not found at $install_script_path"
    fi
}

#####################################################################################################
# MAIN MENU
#####################################################################################################

show_main_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    # NEW: Version number is now hardcoded to 1.2.2 to reflect changes.
    echo -e "${CYAN}║         TurboAsusSec v1.2.2                         ║${NC}"
    echo -e "${CYAN}║      Unified Security Management for ASUS Merlin             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Main Menu:${NC}"
    echo ""
    echo "  1) Overview & Statistics"
    echo "  2) View Merged Whitelist"
    echo "  3) Add to Whitelist"
    echo "  4) View Skynet Recent Blocks"
    echo "  5) AIProtect & Threat Analysis ►"
    echo "  6) System Diagnostics"
    echo "  7) Clear Cache"
    # NEW: Added menu option 8 for updating the script.
    echo "  8) Update Script"
    echo "  0) Exit"
    echo ""
    echo -ne "${CYAN}Enter choice: ${NC}"
}

handle_menu_choice() {
    local choice="$1"
    
    case "$choice" in
        1)
            echo ""
            show_overview
            ;;
        2)
            echo ""
            show_merged_whitelist
            ;;
        3)
            echo ""
            add_to_whitelist_interactive
            ;;
        4)
            echo ""
            show_skynet_logs
            ;;
        5)
            if type handle_aiprotect_menu >/dev/null 2>&1; then
                handle_aiprotect_menu
                return
            else
                print_error "AIProtect module not loaded"
            fi
            ;;
        6)
            if type handle_diagnostics_menu >/dev/null 2>&1; then
                handle_diagnostics_menu
                return
            else
                print_error "Diagnostics module not loaded"
            fi
            ;;
        7)
            clear_all_cache
            print_success "Cache cleared"
            ;;
        # NEW: Added case to handle choice 8, calling the new run_update function.
        8)
            echo ""
            run_update
            ;;
        0|e|E)
            echo ""
            print_success "Goodbye!"
            echo ""
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    
    pause
}

#####################################################################################################
# COMMAND LINE INTERFACE
#####################################################################################################

case "$1" in
    overview)
        show_overview
        ;;
    diagnostics)
        if type handle_diagnostics_menu >/dev/null 2>&1; then
            handle_diagnostics_menu
        else
            echo "Diagnostics module not available"
            exit 1
        fi
        ;;
    whitelist-show)
        show_merged_whitelist
        ;;
    skynet-logs)
        show_skynet_logs
        ;;
    clear-cache)
        clear_all_cache
        echo "Cache cleared"
        ;;
    version)
        echo "TurboAsusSec v1.2.2"
        ;;
    help|--help|-h)
        echo "TurboAsusSec v1.2.2"
        echo ""
        echo "Usage: tcds [command]"
        echo ""
        echo "Commands:"
        echo "  (none)          Interactive menu (default)"
        echo "  overview        Show system overview"
        echo "  diagnostics     Run system diagnostics"
        echo "  whitelist-show  
