#!/bin/sh
#####################################################################################################
# TurboChargeDivSky - AIProtect Analysis Module
# Simple, focused analysis of AIProtect data
#####################################################################################################

# Source core functions
. "$(dirname "$0")/tcds-core.sh"

#####################################################################################################
# DEVICE ANALYSIS
#####################################################################################################

show_affected_devices() {
    print_header "Devices Triggering AIProtect"
    
    if ! aiprotect_available; then
        print_error "AIProtect database not available"
        print_info "Enable AiProtect in router settings: AiProtection"
        return 1
    fi
    
    if ! sqlite_available; then
        print_error "sqlite3 not available - cannot query database"
        return 1
    fi
    
    echo -e "${YELLOW}Devices with Security Events:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    printf "%-17s %-8s %-12s %-12s %-8s\n" "Device IP" "Total" "Malicious" "IPS" "Severity"
    echo "─────────────────────────────────────────────────────────────"
    
    sqlite3 "$AIPROTECT_DB" "
    SELECT 
        src,
        COUNT(*) as total,
        SUM(CASE WHEN type='2' THEN 1 ELSE 0 END) as malicious,
        SUM(CASE WHEN type='3' THEN 1 ELSE 0 END) as ips,
        SUM(CASE WHEN severity='H' THEN 1 ELSE 0 END) as high
    FROM monitor 
    GROUP BY src 
    ORDER BY total DESC 
    LIMIT 20;" 2>/dev/null | while IFS='|' read ip total mal ips high; do
        local severity_indicator=""
        if [ "$high" -gt 0 ]; then
            severity_indicator="${RED}HIGH${NC}"
        elif [ "$ips" -gt 5 ]; then
            severity_indicator="${YELLOW}MED${NC}"
        else
            severity_indicator="${GREEN}LOW${NC}"
        fi
        
        printf "%-17s %-8s %-12s %-12s " "$ip" "$total" "$mal" "$ips"
        echo -e "$severity_indicator"
    done
    
    echo ""
    print_info "High severity = devices with critical security events"
    print_info "Use option to analyze specific device for details"
}

analyze_specific_device() {
    print_header "Device Security Analysis"
    
    if ! aiprotect_available; then
        print_error "AIProtect database not available"
        return 1
    fi
    
    echo -ne "${CYAN}Enter device IP address: ${NC}"
    read device_ip
    
    if [ -z "$device_ip" ]; then
        print_error "No IP address provided"
        return 1
    fi
    
    # Validate IP
    if ! is_valid_ip "$device_ip"; then
        print_error "Invalid IP address format"
        return 1
    fi
    
    echo ""
    print_section "Analysis for $device_ip"
    
    local total=$(sqlite3 "$AIPROTECT_DB" "SELECT COUNT(*) FROM monitor WHERE src='$device_ip';" 2>/dev/null || echo 0)
    
    if [ "$total" -eq 0 ]; then
        print_warning "No security events found for this device"
        print_info "This device either:"
        echo "  • Has not triggered any security alerts"
        echo "  • Is not in the AIProtect database"
        echo "  • Has had its history cleared"
        return 0
    fi
    
    echo "Total security events: $total"
    echo ""
    
    echo "Event Breakdown:"
    sqlite3 "$AIPROTECT_DB" "
    SELECT 
        CASE type 
            WHEN '2' THEN 'Malicious Websites'
            WHEN '3' THEN 'IPS (Intrusion) Events'
            ELSE 'Other'
        END as event_type,
        COUNT(*) as count
    FROM monitor 
    WHERE src='$device_ip' 
    GROUP BY type;" 2>/dev/null | while IFS='|' read type count; do
        printf "  %-25s: %s\n" "$type" "$count"
    done
    
    echo ""
    echo "Recent Events (Last 10):"
    sqlite3 "$AIPROTECT_DB" "
    SELECT 
        datetime(timestamp, 'unixepoch', 'localtime'),
        CASE type WHEN '2' THEN 'Malicious Site' WHEN '3' THEN 'IPS Event' ELSE type END,
        dst
    FROM monitor 
    WHERE src='$device_ip' 
    ORDER BY timestamp DESC 
    LIMIT 10;" 2>/dev/null | while IFS='|' read time type dst; do
        printf "  %s | %-15s | %s\n" "$time" "$type" "$dst"
    done
    
    echo ""
    echo "Top Blocked Destinations for this Device:"
    sqlite3 "$AIPROTECT_DB" "
    SELECT dst, COUNT(*) as count 
    FROM monitor 
    WHERE src='$device_ip' 
    GROUP BY dst 
    ORDER BY count DESC 
    LIMIT 5;" 2>/dev/null | while IFS='|' read dst count; do
        printf "  %s (%s times)\n" "$dst" "$count"
    done
}

#####################################################################################################
# CVE LIST (LAST 2-5 YEARS)
#####################################################################################################

show_recent_cves() {
    print_header "Recent CVEs in Threat Database (Last 5 Years)"
    
    local rules_file="$BWDPI_DB_DIR/bwdpi.rule.db"
    
    if ! bwdpi_available; then
        print_error "BWDPI threat database not found"
        print_info "Expected location: $rules_file"
        return 1
    fi
    
    local current_year=$(date +%Y)
    local start_year=$((current_year - 5))
    
    echo -e "${YELLOW}CVE Coverage ($start_year-$current_year):${NC}"
    echo "─────────────────────────────────────────────────────────────"
    echo ""
    
    echo "CVEs by Year:"
    for year in $(seq $current_year -1 $start_year); do
        local count=$(grep -o "CVE-$year-[0-9]\{4,\}" "$rules_file" 2>/dev/null | sort -u | wc -l)
        printf "  %s: %s CVEs\n" "$year" "$count"
    done
    
    echo ""
    echo -e "${CYAN}Sample Recent CVEs:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    for year in $(seq $current_year -1 $((current_year - 2))); do
        echo ""
        echo "$year CVEs (showing first 10):"
        grep -o "CVE-$year-[0-9]\{4,\}" "$rules_file" 2>/dev/null | sort -u | head -10 | while read cve; do
            echo "  • $cve"
        done
    done
    
    echo ""
    local total_recent=$(grep -o "CVE-$(seq -s'\\|CVE-' $current_year -1 $start_year)-[0-9]\{4,\}" "$rules_file" 2>/dev/null | sort -u | wc -l)
    print_success "Your router can detect $total_recent recent CVEs ($start_year-$current_year)"
    
    echo ""
    print_info "Use CVE Search to check specific vulnerabilities"
}

#####################################################################################################
# CVE SEARCH
#####################################################################################################

search_specific_cve() {
    print_header "Search for Specific CVE"
    
    local rules_file="$BWDPI_DB_DIR/bwdpi.rule.db"
    
    if ! bwdpi_available; then
        print_error "BWDPI threat database not found"
        return 1
    fi
    
    echo -ne "${CYAN}Enter CVE ID (e.g., CVE-2024-1234 or just 2024-1234): ${NC}"
    read cve_input
    
    if [ -z "$cve_input" ]; then
        print_error "No CVE ID provided"
        return 1
    fi
    
    # Add CVE- prefix if not present
    if ! echo "$cve_input" | grep -q "^CVE-"; then
        cve_input="CVE-$cve_input"
    fi
    
    echo ""
    show_progress "Searching for $cve_input"
    sleep 1
    hide_progress
    
    if grep -q "$cve_input" "$rules_file" 2>/dev/null; then
        print_success "CVE FOUND in threat database!"
        echo ""
        echo -e "${GREEN}✓ Your router can detect and block exploits for $cve_input${NC}"
        echo ""
        
        echo "Related security terms found nearby:"
        grep -A5 -B5 "$cve_input" "$rules_file" 2>/dev/null | \
        grep -ao '\(exploit\|vulnerability\|malware\|overflow\|injection\|backdoor\)' | \
        sort -u | while read term; do
            echo "  • $term"
        done
        
        # Check if any devices have triggered this
        echo ""
        echo "Checking if this CVE has been triggered on your network..."
        local triggered=$(sqlite3 "$AIPROTECT_DB" "SELECT COUNT(*) FROM monitor WHERE id LIKE '%$cve_input%';" 2>/dev/null || echo 0)
        if [ "$triggered" -gt 0 ]; then
            print_warning "This CVE was triggered $triggered time(s) on your network!"
        else
            print_success "No devices have triggered this CVE"
        fi
    else
        print_error "CVE NOT FOUND in current threat database"
        echo ""
        echo "This could mean:"
        echo "  • The CVE is too new and not yet in the database"
        echo "  • The vulnerability doesn't affect network traffic patterns"
        echo "  • It's covered by a more general detection rule"
        echo ""
        
        echo "Some recent CVEs in your database:"
        grep -o 'CVE-2024-[0-9]\{4,\}' "$rules_file" 2>/dev/null | sort -u | head -10 | while read cve; do
            echo "  • $cve"
        done
    fi
}

#####################################################################################################
# SUBMENU
#####################################################################################################

show_aiprotect_menu() {
    clear
    print_header "AIProtect & Threat Analysis"
    
    echo -e "${GREEN}Analysis Options:${NC}"
    echo ""
    echo "  1) Show Devices with Security Events"
    echo "  2) Analyze Specific Device"
    echo "  3) Show Recent CVEs (Last 5 Years)"
    echo "  4) Search for Specific CVE"
    echo "  0) Back to Main Menu"
    echo ""
    echo -ne "${CYAN}Enter choice: ${NC}"
}

handle_aiprotect_menu() {
    while true; do
        show_aiprotect_menu
        read choice
        
        case "$choice" in
            1)
                echo ""
                show_affected_devices
                ;;
            2)
                echo ""
                analyze_specific_device
                ;;
            3)
                echo ""
                show_recent_cves
                ;;
            4)
                echo ""
                search_specific_cve
                ;;
            0)
                return 0
                ;;
            *)
                print_error "Invalid choice"
                ;;
        esac
        
        pause
    done
}

# If run directly
if [ "$(basename "$0")" = "tcds-aiprotect.sh" ]; then
    handle_aiprotect_menu
fi
