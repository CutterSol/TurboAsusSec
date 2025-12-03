#!/bin/sh
#####################################################################################################
# TurboAsusSec - System Diagnostics Module
# Comprehensive system and integration checks
#####################################################################################################

# Source core functions if not already loaded
if [ -z "$TCDS_VERSION" ]; then
    . "$(dirname "$0")/tcds-core.sh"
fi

#####################################################################################################
# MAIN DIAGNOSTICS
#####################################################################################################

run_full_diagnostics() {
    clear
    print_header "TurboAsusSec System Diagnostics"
    
    # System Information
    print_section "System Information"
    echo "Script Version: $TCDS_VERSION"
    echo "Router Model: $(get_router_model)"
    echo "Firmware: $(get_firmware_version)"
    echo "Current Time: $(date)"
    echo ""
    
    # Resource Usage
    print_section "Resource Usage"
    free | awk 'NR==2{printf "Memory: %s/%s MB (%.2f%%)\n", $3/1024, $2/1024, $3*100/$2}'
    df -h /jffs 2>/dev/null | awk 'NR==2{print "JFFS Space: " $3 "/" $2 " (" $5 " used)"}'
    df -h /tmp 2>/dev/null | awk 'NR==2{print "TMP Space: " $3 "/" $2 " (" $5 " used)"}'
    echo ""
    
    # Required Commands
    print_section "Required Commands"
    check_command_verbose "ipset" "/usr/sbin/ipset"
    check_command_verbose "sqlite3" "/opt/bin/sqlite3"
    check_command_verbose "grep" "/bin/grep"
    check_command_verbose "awk" "/usr/bin/awk"
    check_co
