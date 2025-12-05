#!/bin/sh

#==================================================================================================
# TurboAsusSec AIProtect Module (tcds-aiprotect.sh)
#==================================================================================================

# This script is sourced by the main tcds.sh script.
# It contains all functions related to the AIProtect & Threat Analysis menu.

show_aiprotect_menu() {
    print_header "AIProtect & Threat Analysis"
    echo "Analysis Options:"
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
            # FIX: Added 'e' and 'E' as exit options for user convenience.
            0|e|E)
                return 0
                ;;
            *)
                print_error "Invalid choice"
                ;;
        esac
        
        pause
    done
}

show_recent_cves() {
    print_header "Recent CVEs in Threat Database (Last 5 Years)"
    
    local rules_file="$BWDPI_DB_DIR/bwdpi.rule.db"
    
    if ! bwdpi_available; then
        print_error "BWDPI threat database not found"
        return 1
    fi
    
    echo "CVE Coverage (2020-2025):"
    echo "─────────────────────────────────────────────────────────────"
    echo ""
    echo "CVEs by Year:"
    
    # FIX: Replaced 'seq' command with a compatible 'while' loop to avoid 'not found' errors on some systems.
    local start_year=2020
    local end_year=$(date +%Y)
    local current_year=$start_year
    local total_cves=0
    
    while [ "$current_year" -le "$end_year" ]; do
        count=$(grep -c "CVE-$current_year-" "$rules_file" 2>/dev/null || echo 0)
        printf "  • %s: %d CVEs\n" "$current_year" "$count"
        total_cves=$((total_cves + count))
        current_year=$((current_year + 1))
    done

    echo ""
    echo "Sample Recent CVEs:"
    echo "─────────────────────────────────────────────────────────────"
    grep -o 'CVE-202[0-9]-[0-9]\{4,\}' "$rules_file" 2>/dev/null | sort -r | head -n 5 | while read -r cve; do
        echo "  • $cve"
    done
    
    echo ""
    if [ "$total_cves" -gt 0 ]; then
        print_success "Your router can detect $total_cves recent CVEs ($start_year-$end_year)"
    else
        print_warning "No recent CVEs found in the database for the years $start_year-$end_year"
    fi
    echo ""
    print_info "Use CVE Search to check specific vulnerabilities"
}

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

# Functions show_affected_devices and analyze_specific_device would also be in this file.
# (Assuming they exist based on the menu)
