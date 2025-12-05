#!/bin/sh
# (Assuming the start of your tcds-diagnostics.sh file is here)

# ... other diagnostic functions ...

check_skynet_integration() {
    echo ""
    print_subheader "Skynet Integration"
    
    if ! skynet_installed; then
        print_warning "Skynet not installed"
        return 1
    fi
    
    print_success "Skynet installed"
    echo "  Location: /jffs/scripts/firewall"
    
    local skynet_path=$(get_skynet_path)
    echo "  Data path: $skynet_path"
    
    local log_file="$skynet_path/skynet.log"
    if [ -f "$log_file" ]; then
        print_success "Log file exists ($(format_size "$log_file"))"
        echo "    Location: $log_file"
    else
        print_error "Log file not found"
    fi
    
    local save_file="$skynet_path/skynet.save"
    if [ -f "$save_file" ]; then
        print_success "IPSet save file exists ($(format_size "$save_file"))"
    fi
    
    echo "  Checking IPSets:"
    # FIX: Replaced the old, unreliable 'command -v' check with the robust direct executable check.
    # This will fix the 'ipset command not available' warning in the diagnostics screen.
    if [ -x "/usr/sbin/ipset" ]; then
        local skynet_sets_count=$(/usr/sbin/ipset list -n 2>/dev/null | grep -c "Skynet-")
        if [ "$skynet_sets_count" -gt 0 ]; then
            print_success "$skynet_sets_count Skynet-related IPSets found"
        else
            print_warning "No Skynet IPSets found"
        fi
    else
        print_error "ipset command not available"
    fi
}

# ... rest of the tcds-diagnostics.sh file ...
