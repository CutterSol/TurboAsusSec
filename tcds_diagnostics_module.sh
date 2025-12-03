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
    check_command_verbose "sed" "/bin/sed"
    check_command_verbose "curl" "/usr/sbin/curl"
    echo ""
    
    # Skynet Integration
    print_section "Skynet Integration"
    if skynet_installed; then
        print_success "Skynet installed"
        echo "  Location: $SKYNET_CMD"
        
        local skynet_version=$("$SKYNET_CMD" version 2>/dev/null | head -1 || echo "Unknown")
        echo "  Version: $skynet_version"
        
        # Check IPSets
        if ipset list Skynet-Whitelist >/dev/null 2>&1; then
            local wl_count=$(ipset list Skynet-Whitelist 2>/dev/null | grep -c "^[0-9]")
            print_success "Whitelist IPSet exists ($wl_count entries)"
        else
            print_warning "Whitelist IPSet not found"
        fi
        
        if ipset list Skynet-Blacklist >/dev/null 2>&1; then
            local bl_count=$(ipset list Skynet-Blacklist 2>/dev/null | grep -c "^[0-9]")
            print_success "Blacklist IPSet exists ($bl_count entries)"
        else
            print_warning "Blacklist IPSet not found"
        fi
        
        # Check Skynet logs
        if [ -f "/tmp/skynet/skynet.log" ]; then
            local log_size=$(du -h /tmp/skynet/skynet.log 2>/dev/null | cut -f1)
            print_success "Log file exists ($log_size)"
        else
            print_warning "Log file not found"
        fi
    else
        print_warning "Skynet not installed"
        echo "  Expected location: $SKYNET_CMD"
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
        fi
    else
        print_warning "AIProtect database not found"
        echo "  Expected location: $AIPROTECT_DB"
        print_info "Enable AiProtect in router settings"
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
        du -sh "$CACHE_DIR" 2>/dev/null | awk '{print "  Total size: " $1}'
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
    else
        print_warning "Skynet script not executable or not found"
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
    print_info "Diagnostics complete"
}

# If run directly
if [ "$(basename "$0")" = "tcds-diagnostics.sh" ]; then
    handle_diagnostics_menu
    pause
fi
