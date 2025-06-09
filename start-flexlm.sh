#!/bin/bash

# Configuration par défaut
VENDOR_NAME="${VENDOR_NAME:-}"
MAX_LOG_SIZE_MB="${MAX_LOG_SIZE_MB:-10}"
LOG_ROTATION_HOURS="${LOG_ROTATION_HOURS:-1}"
RESTART_DELAY="${RESTART_DELAY:-5}"

# Utilisation d'un répertoire temporaire dans le conteneur
export TMPDIR="/opt/flexlm/tmp"
mkdir -p "$TMPDIR"

# Chemins standards FlexLM
LICENSE_PATH="/opt/flexlm/licenses/license.dat"
LOG_DIR="/opt/flexlm/logs"
LOG_FILE="$LOG_DIR/flexlm.log"
ARCHIVE_DIR="$LOG_DIR/archive"
VENDOR_PATH="/opt/flexlm/vendors"
VENDOR_DAEMON="$VENDOR_PATH/$VENDOR_NAME"
PIDFILE="/tmp/flexlm.pid"

# Fonction de logging avec timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction de correction du fichier de licence (sans sed -i)
fix_license_paths() {
    if [ -f "$LICENSE_PATH" ]; then
        # Copie vers un fichier temporaire dans le conteneur
        local temp_file="/opt/flexlm/tmp/license_temp.dat"
        cp "$LICENSE_PATH" "$temp_file" 2>/dev/null || {
            log "WARNING: Cannot backup license file, using original"
            return 0
        }
        
        # Utilisation de sed avec fichier temporaire explicite
        sed "s|:[[:space:]]*/opt/flexlm/|/opt/flexlm/|g" "$LICENSE_PATH" > "$temp_file" 2>/dev/null && \
        sed "s|/opt/flexlm/:/|/opt/flexlm/|g" "$temp_file" > "/opt/flexlm/tmp/license_corrected.dat" 2>/dev/null
        
        log "License file paths corrected"
    fi
}

# Fonction de validation du daemon vendor (insensible à la casse)
validate_vendor_daemon() {
    # Recherche insensible à la casse
    local found_vendor=""
    for vendor_file in "$VENDOR_PATH"/*; do
        if [ -f "$vendor_file" ]; then
            local basename_vendor=$(basename "$vendor_file")
            if [ "${basename_vendor,,}" = "${VENDOR_NAME,,}" ]; then
                found_vendor="$vendor_file"
                VENDOR_DAEMON="$found_vendor"
                log "Found vendor daemon: $found_vendor"
                break
            fi
        fi
    done
    
    if [ -z "$found_vendor" ]; then
        log "ERROR: Vendor daemon $VENDOR_NAME not found at $VENDOR_DAEMON"
        log "Available vendors in $VENDOR_PATH:"
        ls -la "$VENDOR_PATH/" 2>/dev/null || log "Vendor directory not accessible"
        return 1
    fi
    
    if [ ! -x "$VENDOR_DAEMON" ]; then
        log "WARNING: Vendor daemon is not executable, fixing permissions..."
        chmod +x "$VENDOR_DAEMON" 2>/dev/null || {
            log "ERROR: Cannot fix vendor daemon permissions"
            return 1
        }
    fi
    
    return 0
}

# Reste du script...
# (gardez les autres fonctions inchangées)
