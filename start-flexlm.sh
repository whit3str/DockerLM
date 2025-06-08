#!/bin/bash

# Configuration par défaut
VENDOR_NAME="${VENDOR_NAME:-}"
MAX_LOG_SIZE_MB="${MAX_LOG_SIZE_MB:-10}"
LOG_ROTATION_HOURS="${LOG_ROTATION_HOURS:-1}"
RESTART_DELAY="${RESTART_DELAY:-5}"

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

# Fonction de gestion propre des signaux
cleanup() {
    log "Received shutdown signal, stopping FlexLM server..."
    if [ -f "$PIDFILE" ]; then
        LMGRD_PID=$(cat "$PIDFILE")
        if kill -0 "$LMGRD_PID" 2>/dev/null; then
            kill -TERM "$LMGRD_PID"
            sleep 5
            if kill -0 "$LMGRD_PID" 2>/dev/null; then
                kill -9 "$LMGRD_PID"
            fi
        fi
        rm -f "$PIDFILE"
    fi
    exit 0
}

# Configuration des signaux
trap cleanup SIGTERM SIGINT

# Vérification de la présence de VENDOR_NAME
if [ -z "$VENDOR_NAME" ]; then
    log "ERROR: VENDOR_NAME environment variable is not set"
    exit 1
fi

# Création des répertoires nécessaires
mkdir -p "$ARCHIVE_DIR"

# Fonction de rotation des logs améliorée
rotate_logs() {
    if [ -f "$LOG_FILE" ]; then
        size_kb=$(du -k "$LOG_FILE" | cut -f1)
        if [ $size_kb -gt $((MAX_LOG_SIZE_MB * 1024)) ]; then
            timestamp=$(date +%Y%m%d_%H%M%S)
            archive_file="$ARCHIVE_DIR/flexlm_$timestamp.log"
            cp "$LOG_FILE" "$archive_file"
            true > "$LOG_FILE"  # Vide le fichier de log sans le supprimer
            gzip "$archive_file"
            log "Log file rotated to $archive_file.gz"

            # Nettoyage des anciens logs (garde les 10 plus récents)
            find "$ARCHIVE_DIR" -name "flexlm_*.log.gz" -type f | sort -r | tail -n +11 | xargs -r rm
        fi
    fi
}

# Fonction de validation du fichier de licence
validate_license() {
    if [ ! -f "$LICENSE_PATH" ]; then
        log "ERROR: License file not found at $LICENSE_PATH"
        return 1
    fi

    if [ ! -r "$LICENSE_PATH" ]; then
        log "ERROR: License file is not readable"
        return 1
    fi

    # Vérification basique du format
    if ! grep -q "SERVER\|DAEMON\|FEATURE" "$LICENSE_PATH"; then
        log "WARNING: License file format might be invalid"
    fi

    return 0
}

# Fonction de correction du fichier de licence
fix_license_paths() {
    # Sauvegarde avant modification
    cp "$LICENSE_PATH" "$LICENSE_PATH.backup"

    # Correction des chemins
    sed -i "s|:[[:space:]]*/opt/flexlm/|/opt/flexlm/|g" "$LICENSE_PATH"
    sed -i "s|/opt/flexlm/:/|/opt/flexlm/|g" "$LICENSE_PATH"

    log "License file paths corrected"
}

# Fonction de validation du daemon vendor
validate_vendor_daemon() {
    if [ ! -f "$VENDOR_DAEMON" ]; then
        log "ERROR: Vendor daemon $VENDOR_NAME not found at $VENDOR_DAEMON"
        log "Available vendors in $VENDOR_PATH:"
        ls -la "$VENDOR_PATH/" 2>/dev/null || log "Vendor directory not accessible"
        return 1
    fi

    if [ ! -x "$VENDOR_DAEMON" ]; then
        log "WARNING: Vendor daemon $VENDOR_NAME is not executable, fixing permissions..."
        chmod +x "$VENDOR_DAEMON"
    fi

    return 0
}

# Fonction de démarrage du serveur FlexLM
start_flexlm() {
    log "Starting FlexLM server with vendor $VENDOR_NAME..."

    # Rotation des logs existants si nécessaire
    rotate_logs

    # Démarrage avec redirection pour capturer le PID
    /opt/flexlm/bin/lmgrd -c "$LICENSE_PATH" -l "$LOG_FILE" &
    LMGRD_PID=$!
    echo $LMGRD_PID > "$PIDFILE"

    # Attente et vérification du démarrage
    sleep 3

    if kill -0 $LMGRD_PID 2>/dev/null; then
        log "FlexLM server started successfully (PID: $LMGRD_PID)"

        # Affichage des logs de démarrage
        if [ -f "$LOG_FILE" ]; then
            log "---- Latest FlexLM log entries ----"
            tail -n 20 "$LOG_FILE"
            log "---- End of log entries ----"
        fi
        return 0
    else
        log "FlexLM server failed to start"
        rm -f "$PIDFILE"
        return 1
    fi
}

# Fonction de surveillance
monitor_service() {
    local restart_count=0
    local max_restarts=5

    while true; do
        # Rotation périodique des logs
        rotate_logs

        # Vérification du processus
        if [ -f "$PIDFILE" ]; then
            LMGRD_PID=$(cat "$PIDFILE")
            if ! kill -0 "$LMGRD_PID" 2>/dev/null; then
                log "ERROR: FlexLM server process not found (PID: $LMGRD_PID)"

                if [ $restart_count -lt $max_restarts ]; then
                    restart_count=$((restart_count + 1))
                    log "Attempting restart ($restart_count/$max_restarts) in ${RESTART_DELAY}s..."
                    sleep $RESTART_DELAY

                    rm -f "$PIDFILE"
                    if start_flexlm; then
                        restart_count=0  # Reset counter on successful restart
                    fi
                else
                    log "CRITICAL: Maximum restart attempts reached. Exiting."
                    exit 1
                fi
            fi
        else
            log "ERROR: PID file not found, attempting to restart service..."
            if start_flexlm; then
                restart_count=0
            fi
        fi

        sleep $((LOG_ROTATION_HOURS * 3600))
    done
}

# === MAIN EXECUTION ===

log "FlexLM Docker Container Starting..."
log "Vendor: $VENDOR_NAME"
log "License file: $LICENSE_PATH"
log "Log file: $LOG_FILE"
log "Vendor daemon: $VENDOR_DAEMON"

# Validations initiales
validate_license || exit 1
fix_license_paths
validate_vendor_daemon || exit 1

# Démarrage initial
if start_flexlm; then
    log "FlexLM server initialization completed successfully"

    # Surveillance continue
    monitor_service
else
    log "Failed to start FlexLM server during initialization"
    exit 1
fi