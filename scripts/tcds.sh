#!/bin/sh

#==================================================================================================
# TurboAsusSec Main Script (tcds.sh)
#==================================================================================================

# --- SCRIPT CONFIGURATION AND HELPER FUNCTIONS ---
# (Assuming variables like TCDS_VERSION, color codes, print_header, etc. are here)

# FIX: Modified command_exists to be more robust for embedded systems.
# It now checks for the executable file directly instead of relying on 'command -v'.
# This resolves the 'ipset command not available' error in Diagnostics and Whitelist view.
command_exists() {
    # Check common paths for system utilities
    for path in /bin /sbin /usr/bin /usr/sbin /opt/bin /opt/sbin; do
        if [ -x "$path/$1" ]; then
            return 0
        fi
    done
    # Fallback to 'which' if available, as it's more common than 'command -v'
    if which "$1" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# --- MENU DEFINITIONS ---

show_main_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         TurboAsusSec v1.2.2                         ║${NC}" # NEW: Version bump
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
    echo "  8) Update Script" # NEW: Added Update option
    echo "  0) Exit"
    echo ""
    echo -ne "${CYAN}Enter choice: ${NC}"
}

# --- CORE FUNCTIONS ---

# (Assuming other functions like show_overview, add_to_whitelist are here)

show_merged_whitelist() {
    print_header "Merged Whitelist"
    
    # ... (code for Diversion and Custom whitelists) ...
    
    # Skynet Whitelist
    # FIX: Use the corrected 'command_exists' check.
    if command_exists "ipset"; then
        echo "Processing Skynet Whitelist..."
        # FIX: Call ipset with its full, reliable path.
        /usr/sbin/ipset list Skynet-Whitelist -o save 2>/dev/null | grep -vE "^(create|add)" | while read -r entry; do
            # ... (logic to process and print entries) ...
        done
    else
        print_warning "ipset command not found, cannot display Skynet whitelist."
    fi
    
    # ... (rest of the function) ...
}

show_skynet_logs() {
    print_header "Skynet Recent Blocks"
    
    # FIX: Implemented more robust Skynet log file detection.
    # It now checks multiple common locations, similar to how other integrations are detected.
    local skynet_log_path=""
    local potential_paths=$(find /tmp/mnt -name "skynet.log" 2>/dev/null)

    if [ -n "$potential_paths" ]; then
        # Use the first one found
        skynet_log_path=$(echo "$potential_paths" | head -n 1)
    elif [ -f "/jffs/skynet/skynet.log" ]; then # Fallback for non-USB installs
        skynet_log_path="/jffs/skynet/skynet.log"
    fi

    if [ -f "$skynet_log_path" ]; then
        print_info "Displaying last 20 entries from: $skynet_log_path"
        echo "─────────────────────────────────────────────────────────────"
        grep "BLOCKED" "$skynet_log_path" | tail -n 20
        echo "─────────────────────────────────────────────────────────────"
    else
        print_error "Skynet log file could not be found."
        print_info "Checked common locations like /tmp/mnt/*/skynet/skynet.log"
    fi
}

run_update() {
    print_header "Update Script"
    local install_script_path
    # Find the install script relative to the running script
    install_script_path="$(dirname "$0")/../install.sh"
    
    if [ -f "$install_script_path" ]; then
        echo "Found install/update script at: $install_script_path"
        echo "The installer will now check for the latest version."
        echo ""
        # The install script should handle the rest (checking version, downloading, etc.)
        sh "$install_script_path"
    else
        print_error "Update failed: install.sh not found."
        print_info "Please run the update manually from the original project directory."
    fi
}

# --- MAIN SCRIPT LOGIC ---

# Source other script files
# . /path/to/tcds-aiprotect.sh
# . /path/to/tcds-diagnostics.sh

while true; do
    show_main_menu
    read choice
    
    case "$choice" in
        1) show_overview ;;
        2) show_merged_whitelist ;;
        3) add_to_whitelist ;;
        4) show_skynet_logs ;;
        5) handle_aiprotect_menu ;; # This function is in tcds-aiprotect.sh
        6) run_diagnostics ;;
        7) clear_cache ;;
        # NEW: Handle the update choice
        8)
            echo ""
            run_update
            ;;
        0|e|E)
            echo "Exiting."
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    pause
done

