#!/bin/sh
#####################################################################################################
# TurboChargeDivSky - Core Functions
# Shared utilities and functions used by all modules
#####################################################################################################

# Version
TCDS_VERSION="1.2.0"

# Paths
INSTALL_DIR="/jffs/addons/tcds"
SCRIPT_DIR="$INSTALL_DIR/scripts"
CACHE_DIR="/tmp/tcds"
LOG_FILE="$INSTALL_DIR/logs/tcds.log"

# Integration paths
SKYNET_CMD="/jffs/scripts/firewall"
DIVERSION_PATH="/opt/share/diversion"
AIPROTECT_DB="/jffs/.sys/AiProtectionMonitor/AiProtectionMonitor.db"
BWDPI_DB_DIR="/tmp/bwdpi"

# Configuration
CACHE_TTL=600  # 10 minutes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

#####################################################################################################
# INITIALIZATION
#####################################################################################################

# Ensure cache directory exists
[ ! -d "$CACHE_DIR" ] && mkdir -p "$CACHE_DIR"

# Ensure log directory exists
[ ! -d "$INSTALL_DIR/logs" ] && mkdir -p "$INSTALL_DIR/logs"

#####################################################################################################
# LOGGING
#####################################################################################################

log_msg() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" >> "$LOG_FILE"
    logger -t "TurboChargeDivSky" "$msg"
}

log_error() {
    log_msg "ERROR: $1"
}

log_info() {
    log_msg "INFO: $1"
}

log_debug() {
    [ -n "$TCDS_DEBUG" ] && log_msg "DEBUG: $1"
}

#####################################################################################################
# CACHE MANAGEMENT
#####################################################################################################

check_cache_valid() {
    local cache_file="$1"
    local time_file="${cache_file}.time"
    
    [ ! -f "$cache_file" ] && return 1
    [ ! -f "$time_file" ] && return 1
    
    local cache_age=$(($(date +%s) - $(cat "$time_file" 2>/dev/null || echo 0)))
    [ "$cache_age" -lt "$CACHE_TTL" ] && return 0
    return 1
}

update_cache_time() {
    local cache_file="$1"
    date +%s > "${cache_file}.time"
}

clear_all_cache() {
    rm -f "$CACHE_DIR"/*.cache "$CACHE_DIR"/*.time 2>/dev/null
    log_info "Cache cleared"
}

#####################################################################################################
# INTEGRATION DETECTION
#####################################################################################################

skynet_installed() {
    [ -f "$SKYNET_CMD" ] && [ -x "$SKYNET_CMD" ]
}

diversion_installed() {
    [ -d "$DIVERSION_PATH" ] && [ -d "$DIVERSION_PATH/list" ]
}

aiprotect_available() {
    [ -f "$AIPROTECT_DB" ]
}

bwdpi_available() {
    [ -d "$BWDPI_DB_DIR" ] && [ -f "$BWDPI_DB_DIR/bwdpi.rule.db" ]
}

sqlite_available() {
    command -v sqlite3 >/dev/null 2>&1 || [ -x "/opt/bin/sqlite3" ]
}

# Get Skynet data path (handles USB mounts)
get_skynet_path() {
    # Check standard location first
    if [ -d "/tmp/skynet" ]; then
        echo "/tmp/skynet"
        return 0
    fi
    
    # Check USB mounts
    local skynet_path=$(find /tmp/mnt -type d -name "skynet" 2>/dev/null | head -1)
    if [ -n "$skynet_path" ] && [ -f "$skynet_path/skynet.log" ]; then
        echo "$skynet_path"
        return 0
    fi
    
    return 1
}

#####################################################################################################
# SYSTEM CHECKS
#####################################################################################################

check_merlin() {
    grep -q "asuswrt-merlin" /etc/issue 2>/dev/null || [ -f "/usr/sbin/helper.sh" ]
}

get_router_model() {
    nvram get productid 2>/dev/null || echo "Unknown"
}

get_firmware_version() {
    nvram get buildno 2>/dev/null || echo "Unknown"
}

#####################################################################################################
# DATA SANITIZATION
#####################################################################################################

# Validate IP address format
is_valid_ip() {
    local ip="$1"
    echo "$ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

# Validate domain format
is_valid_domain() {
    local domain="$1"
    echo "$domain" | grep -Eq '^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
}

# Sanitize input (remove special characters)
sanitize_input() {
    local input="$1"
    echo "$input" | tr -cd '[:alnum:]._-'
}

#####################################################################################################
# FILE OPERATIONS
#####################################################################################################

# Safe file append (creates if doesn't exist)
safe_append() {
    local file="$1"
    local content="$2"
    
    [ ! -f "$file" ] && touch "$file"
    
    if [ -w "$file" ]; then
        echo "$content" >> "$file"
        return 0
    else
        log_error "Cannot write to $file"
        return 1
    fi
}

# Safe file remove line
safe_remove_line() {
    local file="$1"
    local pattern="$2"
    
    if [ -f "$file" ] && [ -w "$file" ]; then
        sed -i "/^${pattern}$/d" "$file"
        return 0
    else
        log_error "Cannot modify $file"
        return 1
    fi
}

# Check if file is writable
is_writable() {
    local file="$1"
    [ -w "$file" ] || [ -w "$(dirname "$file")" ]
}

#####################################################################################################
# DISPLAY HELPERS
#####################################################################################################

print_header() {
    local title="$1"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║ %-60s ║${NC}\n" "$title"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    local title="$1"
    echo -e "\n${MAGENTA}▶ $title${NC}"
    echo "─────────────────────────────────────────────────────────────"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Progress indicator
show_progress() {
    echo -ne "${YELLOW}$1...${NC}\r"
}

hide_progress() {
    echo -ne "\033[2K\r"
}

#####################################################################################################
# INTERACTIVE HELPERS
#####################################################################################################

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    
    local prompt="(y/n)"
    [ "$default" = "y" ] && prompt="(Y/n)" || prompt="(y/N)"
    
    echo -ne "${CYAN}$question $prompt: ${NC}"
    read answer
    
    answer="${answer:-$default}"
    [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}

# Wait for Enter key
pause() {
    echo ""
    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read
}

#####################################################################################################
# ERROR HANDLING
#####################################################################################################

# Exit with error message
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    log_error "$1"
    exit 1
}

# Warn but continue
warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
    log_msg "WARNING: $1"
}

#####################################################################################################
# VERSION COMPARISON
#####################################################################################################

# Compare version strings (returns 0 if v1 < v2, 1 if v1 == v2, 2 if v1 > v2)
# POSIX-compliant version
version_compare() {
    local v1="$1"
    local v2="$2"
    
    if [ "$v1" = "$v2" ]; then
        return 1
    fi
    
    # Simple string comparison for basic version checking
    # Works for most cases like 1.2.0 vs 1.3.0
    local v1_major=$(echo "$v1" | cut -d. -f1)
    local v1_minor=$(echo "$v1" | cut -d. -f2)
    local v1_patch=$(echo "$v1" | cut -d. -f3)
    
    local v2_major=$(echo "$v2" | cut -d. -f1)
    local v2_minor=$(echo "$v2" | cut -d. -f2)
    local v2_patch=$(echo "$v2" | cut -d. -f3)
    
    # Compare major version
    if [ "$v1_major" -lt "$v2_major" ]; then
        return 0
    elif [ "$v1_major" -gt "$v2_major" ]; then
        return 2
    fi
    
    # Compare minor version
    if [ "$v1_minor" -lt "$v2_minor" ]; then
        return 0
    elif [ "$v1_minor" -gt "$v2_minor" ]; then
        return 2
    fi
    
    # Compare patch version
    if [ "$v1_patch" -lt "$v2_patch" ]; then
        return 0
    elif [ "$v1_patch" -gt "$v2_patch" ]; then
        return 2
    fi
    
    return 1
}

#####################################################################################################
# RESOURCE MONITORING
#####################################################################################################

get_memory_usage() {
    free | awk 'NR==2{printf "%.2f", $3*100/$2}'
}

get_jffs_usage() {
    df -h /jffs 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%'
}

check_low_memory() {
    local usage=$(get_memory_usage)
    local threshold=90
    
    if [ "${usage%.*}" -gt "$threshold" ]; then
        warn "Memory usage is high: ${usage}%"
        return 0
    fi
    return 1
}

#####################################################################################################
# MODULE LOADING
#####################################################################################################

# Source a module script
load_module() {
    local module="$1"
    local module_path="$SCRIPT_DIR/$module"
    
    if [ -f "$module_path" ]; then
        . "$module_path"
        log_debug "Loaded module: $module"
        return 0
    else
        log_error "Module not found: $module"
        return 1
    fi
}

#####################################################################################################
# INITIALIZATION COMPLETE
#####################################################################################################

log_debug "Core module loaded (v$TCDS_VERSION)"
