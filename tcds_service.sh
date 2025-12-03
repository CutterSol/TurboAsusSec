#!/bin/sh
#####################################################################################################
# TurboAsusSec - Service Event Handler
# Handles service restart events from the router
#####################################################################################################

TYPE=$1
EVENT=$2

INSTALL_DIR="/jffs/addons/tcds"
SCRIPT_DIR="$INSTALL_DIR/scripts"

# Source core if available
if [ -f "$SCRIPT_DIR/tcds-core.sh" ]; then
    . "$SCRIPT_DIR/tcds-core.sh"
fi

# Handle TurboAsusSec service events
if [ "$EVENT" = "tcds" ] && [ "$TYPE" = "restart" ]; then
    logger -t "TurboAsusSec" "Service restart requested"
    
    # Clear cache on restart
    rm -f /tmp/tcds/*.cache 2>/dev/null
    
    # Reload configuration if needed
    if [ -f "$SCRIPT_DIR/tcds.sh" ]; then
        logger -t "TurboAsusSec" "Reloaded successfully"
    else
        logger -t "TurboAsusSec" "ERROR: Main script not found"
    fi
fi
