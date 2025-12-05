#!/bin/sh
#####################################################################################################
# TurboAsusSec - System Diagnostics Module v1.2.1
# Comprehensive system and integration checks
#####################################################################################################

# Source core functions if not already loaded
if [ -z "$TCDS_VERSION" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    . "$SCRIPT_DIR/tcds-core.sh"
fi

#####################################################################################################
# SKYNET PATH DETECTION
#####################################################################################################

find_skynet_path() {
    # Check common locations
    if [ -f "/tmp/skynet/skynet.log" ]; then
        echo "/tmp/skynet"
        return 0
    fi
    
    # Check USB mounts
    local skynet_path=$(find /tmp/mnt -path "*/skynet/skynet.log" 2>/dev/null | head -1)
    if [ -n "$skynet_path" ]; then
        dirname "$skynet_path"
        return 0
    fi
    
    return 1
}

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
    check_command_verbose "sed" "/bin/sed"
    check_command_verbose "curl" "/usr/sbin/curl"
    echo ""
    
    # Skynet Integration with dynamic path detection
    print_section "Skynet Integration"
    if skynet_installed; then
        print_success "Skynet installed"
        echo "  Location: $SKYNET_CMD"
        
        local skynet_version=$("$SKYNET_CMD" version 2>/dev/null | head -1 || echo "Unknown")
        echo "  Version: $skynet_version"
        
        # Find actual Skynet data path
        local skynet_data_path=$(find_skynet_path)
        if [ -n "$skynet_data_path" ]; then
            echo "  Data path: $skynet_data_path"
            
            # Check for log file
            if [ -f "$skynet_data_path/skynet.log" ]; then
                local log_size=$(du -h "$skynet_data_path/skynet.log" 2>/dev/null | cut -f1)
                print_success "Log file exists ($log_size)"
                echo "    Location: $skynet_data_path/skynet.log"
            else
                print_warning "Log file not found"
            fi
            
            # Check for IPSet save file
            if [ -f "$skynet_data_path/skynet.ipset" ]; then
                local ipset_size=$(du -h "$skynet_data_path/skynet.ipset" 2>/dev/null | cut -f1)
                print_success "IPSet save file exists ($ipset_size)"
            else
                print_warning "IPSet save file not found"
            fi
        else
            print_warning "Skynet data path not found (checked /tmp/skynet and USB mounts)"
        fi
        
        # Check IPSets - these might not exist if Skynet just installed
        echo "  Checking IPSets:"
        local ipsets_found=0
        
        # List all Skynet-related IPSets
        if command -v ipset >/dev/null 2>&1; then
            local skynet_ipsets=$(ipset list -n 2>/dev/null | grep -i skynet)
            if [ -n "$skynet_ipsets" ]; then
                echo "$skynet_ipsets" | while read ipset_name; do
                    local count=$(ipset list "$ipset_name" 2>/dev/null | grep -c "^[0-9]")
                    echo "    • $ipset_name: $count entries"
                    ipsets_found=1
                done
            else
                print_warning "No Skynet IPSets found (Skynet may need to be started)"
            fi
        else
            print_warning "ipset command not available"
        fi
    else
        print_warning "Skynet not installed"
        echo "  Expected location: $SKYNET_CMD"
        print_info "Install Skynet: https://github.com/Adamm00/IPSet_ASUS"
    fi
    echo ""
    
    # Diversion Integration
    print_section "Diversion Integration"
    if diversion_installed; then
        print_success "Diversion installed"
        echo "  Location: $DIVERSION_PATH"
        
        if [ -d "$DIVERSION_PATH/list" ]; then
            echo "  List directory contents:"
            ls -lh "$DIVERSION_PATH/list/" 2>/dev/null | grep -v "^total" | awk '{print "    " $9 " (" $5 ")"}'
            
            if [ -f "$DIVERSION_PATH/list/allowlist" ]; then
                local al_count=$(wc -l < "$DIVERSION_PATH/list/allowlist" 2>/dev/null || echo 0)
                print_success "Allowlist exists ($al_count entries)"
            else
                print_warning "Allowlist not found"
            fi
            
            if [ -f "$DIVERSION_PATH/list/denylist" ]; then
                local dl_count=$(wc -l < "$DIVERSION_PATH/list/denylist" 2>/dev/null || echo 0)
                print_success "Denylist exists ($dl_count entries)"
            else
                print_warning "Denylist not found"
            fi
            
            if [ -f "$DIVERSION_PATH/list/blockinglist.conf" ]; then
                local bl_size=$(du -h "$DIVERSION_PATH/list/blockinglist.conf" 2>/dev/null | cut -f1)
                print_success "Blockinglist exists ($bl_size)"
            else
                print_warning "Blockinglist not found"
            fi
        else
            print_error "List directory not found"
        fi
    else
        print_warning "Diversion not installed"
        echo "  Expected location: $DIVERSION_PATH"
        print_info "Install Diversion via amtm"
    fi
    echo ""
    
    # AIProtect Detection
    print_section "AIProtect Integration"
    if aiprotect_available; then
        print_success "AIProtect database available"
        echo "  Location: $AIPROTECT_DB"
        
        local db_size=$(du -h "$AIPROTECT_DB" 2>/dev/null | cut -f1)
        echo "  Size: $db_size"
        
        if sqlite_available; then
            if sqlite3 "$AIPROTECT_DB" "SELECT 1" >/dev/null 2>&1; then
                local total_events=$(sqlite3 "$AIPROTECT_DB" "SELECT COUNT(*) FROM monitor;" 2>/dev/null || echo "0")
                echo "  Total events: $total_events"
                
                echo "  Event types:"
                sqlite3 "$AIPROTECT_DB" "SELECT type, COUNT(*) FROM monitor GROUP BY type;" 2>/dev/null | while IFS='|' read type count; do
                    case "$type" in
                        2) echo "    Type 2 (Malicious Sites): $count" ;;
                        3) echo "    Type 3 (IPS Events): $count" ;;
                        *) echo "    Type $type: $count" ;;
                    esac
                done
            else
                print_warning "Cannot query database"
            fi
        else
            print_warning "sqlite3 not available - cannot query database"
            print_info "Install: opkg install sqlite3-cli"
        fi
    else
        print_warning "AIProtect database not found"
        echo "  Expected location: $AIPROTECT_DB"
        print_info "Enable AiProtect in router settings (AiProtection)"
    fi
    echo ""
    
    # BWDPI Threat Database
    print_section "BWDPI Threat Database"
    if bwdpi_available; then
        print_success "BWDPI directory found"
        echo "  Location: $BWDPI_DB_DIR"
        
        local rules_file="$BWDPI_DB_DIR/bwdpi.rule.db"
        if [ -f "$rules_file" ]; then
            local rules_size=$(du -h "$rules_file" 2>/dev/null | cut -f1)
            print_success "Rules database exists ($rules_size)"
            
            local cve_count=$(grep -o 'CVE-[0-9]\{4\}-[0-9]\{4,\}' "$rules_file" 2>/dev/null | sort -u | wc -l)
            echo "  CVE signatures: $cve_count"
        else
            print_warning "Rules database not found"
        fi
    else
        print_warning "BWDPI directory not found"
        echo "  Expected location: $BWDPI_DB_DIR"
    fi
    echo ""
    
    # DNS Logs
    print_section "DNS Log Detection"
    local dnsmasq_logs=$(find /opt/var/log /tmp -name "dnsmasq.log*" 2>/dev/null | head -5)
    if [ -n "$dnsmasq_logs" ]; then
        print_success "DNS logs found:"
        echo "$dnsmasq_logs" | while read log; do
            local log_size=$(du -h "$log" 2>/dev/null | cut -f1)
            echo "  $log ($log_size)"
        done
    else
        print_warning "No dnsmasq logs found"
    fi
    echo ""
    
    # TurboAsusSec Files
    print_section "TurboAsusSec Files"
    check_file_verbose "$INSTALL_DIR/custom_whitelist.txt" "Custom whitelist"
    check_file_verbose "$INSTALL_DIR/custom_blacklist.txt" "Custom blacklist"
    check_file_verbose "$INSTALL_DIR/logs/tcds.log" "Activity log"
    
    echo ""
    echo "Cache directory: $CACHE_DIR"
    if [ -d "$CACHE_DIR" ]; then
        local cache_files=$(ls -1 "$CACHE_DIR" 2>/dev/null | wc -l)
        echo "  Cache files: $cache_files"
        if [ "$cache_files" -gt 0 ]; then
            du -sh "$CACHE_DIR" 2>/dev/null | awk '{print "  Total size: " $1}'
        else
            echo "  Total size: 0"
        fi
    else
        print_warning "Cache directory not found"
    fi
    echo ""
    
    # Permissions Check
    print_section "Permissions Check"
    
    if touch "$INSTALL_DIR/custom_whitelist.txt" 2>/dev/null; then
        print_success "Can write to custom whitelist"
    else
        print_error "Cannot write to custom whitelist"
    fi
    
    if [ -x "$SKYNET_CMD" ]; then
        print_success "Skynet script is executable"
    elif [ -f "$SKYNET_CMD" ]; then
        print_warning "Skynet script exists but not executable"
    fi
    
    echo ""
    
    # Integration Summary
    print_section "Integration Summary"
    local integrations=0
    skynet_installed && integrations=$((integrations + 1)) && print_success "Skynet"
    diversion_installed && integrations=$((integrations + 1)) && print_success "Diversion"
    aiprotect_available && integrations=$((integrations + 1)) && print_success "AIProtect"
    
    echo ""
    echo "Active integrations: $integrations/3"
    echo ""
    
    if [ "$integrations" -eq 0 ]; then
        print_warning "No integrations detected!"
        print_info "Install Skynet and/or Diversion for full functionality"
    fi
    
    print_info "Diagnostics complete"
}

#####################################################################################################
# HELPER FUNCTIONS
#####################################################################################################

check_command_verbose() {
    local cmd="$1"
    local path="$2"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        print_success "$cmd available"
    elif [ -n "$path" ] && [ -x "$path" ]; then
        print_success "$cmd available at $path"
    else
        print_error "$cmd not found"
    fi
}

check_file_verbose() {
    local file="$1"
    local desc="$2"
    
    if [ -f "$file" ]; then
        local size=$(du -h "$file" 2>/dev/null | cut -f1)
        print_success "$desc exists ($size)"
    else
        print_warning "$desc not found"
    fi
}

#####################################################################################################
# MENU INTERFACE
#####################################################################################################

handle_diagnostics_menu() {
    run_full_diagnostics
    
    echo ""
    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read
}

# If run directly
if [ "$(basename "$0")" = "tcds-diagnostics.sh" ]; then
    handle_diagnostics_menu
fi
