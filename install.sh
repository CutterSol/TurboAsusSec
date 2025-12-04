#!/bin/sh
#####################################################################################################
# TurboAsusSec Installer (Patched)
# One-command installation for ASUS Merlin routers
# Version 1.2.1 (patched)
#
# Installation:
# curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/master/install.sh | sh
#####################################################################################################

VERSION="1.2.1"
REPO_URL="https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main"
INSTALL_DIR="/jffs/addons/tcds"
SCRIPT_DIR="$INSTALL_DIR/scripts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PROFILE_ADD="/jffs/configs/profile.add"
MAIN_SCRIPT="$SCRIPT_DIR/tcds.sh"
ALIAS_LINE='alias tcds="sh /jffs/addons/tcds/scripts/tcds.sh" # added by TurboAsusSec'

log() {
    printf "%b\n" "$1"
}

backup_file() {
    file="$1"
    if [ -e "$file" ]; then
        cp -a "$file" "$file.$(date +%Y%m%d_%H%M%S).bak" 2>/dev/null || true
        log "Backup created for $file"
    fi
}

add_alias() {
    if [ ! -f "$PROFILE_ADD" ]; then
        printf '# TurboAsusSec profile.add created\n' > "$PROFILE_ADD"
        chmod 644 "$PROFILE_ADD"
    fi

    if ! grep -Fq 'alias tcds=' "$PROFILE_ADD"; then
        backup_file "$PROFILE_ADD"
        echo "$ALIAS_LINE" >> "$PROFILE_ADD"
        log "Alias added to profile.add"
        # Attempt to source immediately
        if . "$PROFILE_ADD" 2>/dev/null; then
            log "Profile sourced successfully"
        else
            log "Profile could not be sourced automatically; source manually if needed"
        fi
    fi
}

remove_alias() {
    if [ -f "$PROFILE_ADD" ]; then
        backup_file "$PROFILE_ADD"
        sed -i '/alias tcds=/d' "$PROFILE_ADD" 2>/dev/null || true
        log "Alias removed from profile.add"
    fi
}

create_symlink() {
    if [ -f "$MAIN_SCRIPT" ]; then
        ln -sf "$MAIN_SCRIPT" /jffs/scripts/tcds
        chmod +x "$MAIN_SCRIPT"
        log "Symlink created: /jffs/scripts/tcds -> $MAIN_SCRIPT"
    fi
}

remove_symlink() {
    if [ -L "/jffs/scripts/tcds" ] || [ -f "/jffs/scripts/tcds" ]; then
        rm -f /jffs/scripts/tcds
        log "Symlink /jffs/scripts/tcds removed"
    fi
}

install_scripts() {
    mkdir -p "$SCRIPT_DIR" 2>/dev/null || log "Could not create script directory"
    scripts="tcds.sh tcds-core.sh tcds-aiprotect.sh tcds-diagnostics.sh tcds-whitelist.sh tcds-service.sh"
    for s in $scripts; do
        url="$REPO_URL/scripts/$s"
        dest="$SCRIPT_DIR/$s"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$url" -o "$dest" || log "Failed to download $s"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$dest" "$url" || log "Failed to download $s"
        else
            log "No downloader available for $s"
        fi
        chmod +x "$dest" 2>/dev/null || true
    done
}

uninstall() {
    printf "WARNING: This will uninstall TurboAsusSec. Type 'yes' to continue: "
    read ans
    if [ "$ans" != "yes" ]; then
        log "Uninstall cancelled"
        exit 0
    fi
    remove_alias
    remove_symlink
    if [ -d "$INSTALL_DIR" ]; then
        backup_file "$INSTALL_DIR"
        rm -rf "$INSTALL_DIR"
        log "$INSTALL_DIR removed"
    fi
    log "Uninstall complete"
    exit 0
}

update() {
    log "Updating TurboAsusSec..."
    install_scripts
    create_symlink
    add_alias
    log "Update complete"
    exit 0
}

install() {
    log "Installing TurboAsusSec..."
    install_scripts
    create_symlink
    add_alias
    log "Installation complete"
    exit 0
}

# Main menu / argument handling
case "$1" in
    install) install ;; 
    update) update ;; 
    uninstall) uninstall ;; 
    '')
        printf "TurboAsusSec Installer v%s\n" "$VERSION"
        printf "1) Install\n2) Update\n3) Uninstall\n0) Exit\nSelect: "
        read choice
        case "$choice" in
            1) install ;;
            2) update ;;
            3) uninstall ;;
            0|e|exit) log "Exiting." ;;
            *) log "Invalid selection" ;;
        esac
        ;;
    *) log "Usage: $0 [install|update|uninstall]" ;;
esac
exit 0
