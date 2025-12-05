#!/bin/sh
#####################################################################################################
# TurboChargeDivSky - AIProtect Analysis Module
# Simple, focused analysis of AIProtect data
#####################################################################################################

# (The script is identical to the one you approved, down to the last function)
# ...

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
    local year=$current_year
    while [ "$year" -ge "$start_year" ]; do
        local count=$(grep -o "CVE-$year-[0-9]\{4,\}" "$rules_file" 2>/dev/null | sort -u | wc -l)
        printf "  %s: %s CVEs\n" "$year" "$count"
        year=$((year - 1))
    done
    
    echo ""
    echo -e "${CYAN}Sample Recent CVEs:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    local year=$current_year
    local end_sample_year=$((current_year - 2))
    while [ "$year" -ge "$end_sample_year" ]; do
        echo ""
        echo "$year CVEs (showing first 10):"
        grep -o "CVE-$year-[0-9]\{4,\}" "$rules_file" 2>/dev/null | sort -u | head -10 | while read cve; do
            echo "  • $cve"
        done
        year=$((year - 1))
    done
    
    echo ""
    # FIX: Replaced the final 'seq' command with a compatible 'grep' pattern.
    # This resolves the 'seq: not found' error in the summary line.
    local year_pattern=""
    local i=$start_year
    while [ $i -le $current_year ]; do
        if [ -z "$year_pattern" ]; then
            year_pattern="$i"
        else
            year_pattern="$year_pattern\|$i"
        fi
        i=$((i + 1))
    done
    local total_recent=$(grep -Eo "CVE-($year_pattern)-" "$rules_file" 2>/dev/null | sort -u | wc -l)
    print_success "Your router can detect $total_recent recent CVEs ($start_year-$current_year)"
    
    echo ""
    print_info "Use CVE Search to check specific vulnerabilities"
}

# (The rest of the script is unchanged)
# ...
