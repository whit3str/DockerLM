#!/bin/bash

# Configuration
VENDOR_NAME="${VENDOR_NAME:-}"
LICENSE_PATH="/opt/flexlm/licenses/license.dat"
LOG_DIR="/opt/flexlm/logs"
LOG_FILE="$LOG_DIR/flexlm.log"
VENDOR_LOG="$LOG_DIR/${VENDOR_NAME}.log"
VENDOR_DAEMON="/opt/flexlm/vendors/${VENDOR_NAME}"
MAX_LOG_SIZE_MB="${MAX_LOG_SIZE_MB:-10}"
LOG_ROTATION_HOURS="${LOG_ROTATION_HOURS:-1}"
RESTART_DELAY="${RESTART_DELAY:-5}"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/startup.log"
}

# Gestion propre des signaux
cleanup() {
    log "Arrêt du serveur FlexLM..."
    if [ -n "$LMGRD_PID" ] && kill -0 $LMGRD_PID 2>/dev/null; then
        kill $LMGRD_PID
        wait $LMGRD_PID 2>/dev/null
    fi
    log "Serveur FlexLM arrêté"
    exit 0
}
trap cleanup SIGTERM SIGINT

# Vérification et création des répertoires
mkdir -p "$LOG_DIR"

# Fonction de rotation des logs
rotate_logs() {
    local log_file=$1
    local max_size_mb=$2
    
    if [ -f "$log_file" ]; then
        # Taille du fichier en Mo
        local size_mb=$(du -m "$log_file" | cut -f1)
        
        if [ "$size_mb" -ge "$max_size_mb" ]; then
            local timestamp=$(date +%Y%m%d_%H%M%S)
            log "Rotation du fichier log: $log_file (${size_mb}MB)"
            mv "$log_file" "${log_file}.${timestamp}"
            
            # Limiter le nombre de logs archivés (garder les 5 plus récents)
            ls -t "${log_file}."* 2>/dev/null | tail -n +6 | xargs -r rm
        fi
    fi
}

# Vérifications essentielles
if [ -z "$VENDOR_NAME" ]; then
    log "ERREUR: VENDOR_NAME non défini"
    exit 1
fi

if [ ! -f "$LICENSE_PATH" ]; then
    log "ERREUR: Fichier de licence introuvable: $LICENSE_PATH"
    exit 1
fi

if [ ! -f "$VENDOR_DAEMON" ]; then
    log "ERREUR: Daemon vendor introuvable: $VENDOR_DAEMON"
    exit 1
fi

# Vérification des binaires
if [ ! -f "/opt/flexlm/bin/lmgrd" ]; then
    log "ERREUR: Binaire lmgrd introuvable"
    exit 1
fi

if [ ! -f "/opt/flexlm/bin/lmutil" ]; then
    log "ERREUR: Binaire lmutil introuvable"
    exit 1
fi

# Affichage des informations
log "Démarrage du serveur FlexLM"
log "  - Vendor: $VENDOR_NAME"
log "  - License: $LICENSE_PATH"
log "  - Daemon: $VENDOR_DAEMON"
log "  - Hostname: $(hostname)"
log "  - MAC Address: $(ip link | grep -A1 eth0 | tail -n1 | awk '{print $2}')"

# Boucle principale avec redémarrage en cas d'erreur
while true; do
    # Rotation des logs
    rotate_logs "$LOG_FILE" "$MAX_LOG_SIZE_MB"
    rotate_logs "$VENDOR_LOG" "$MAX_LOG_SIZE_MB"
    
    # Démarrage du serveur
    log "Démarrage FlexLM avec vendor: $VENDOR_NAME"
    /opt/flexlm/bin/lmgrd -c "$LICENSE_PATH" -l "$LOG_FILE" &
    LMGRD_PID=$!
    
    # Attente et vérification
    sleep 3
    if kill -0 $LMGRD_PID 2>/dev/null; then
        log "FlexLM démarré avec succès (PID: $LMGRD_PID)"
        
        # Affichage de l'état du serveur
        sleep 2
        /opt/flexlm/bin/lmutil lmstat -c "$LICENSE_PATH" -a >> "$LOG_DIR/startup.log" 2>&1
        
        # Attente que le processus se termine
        wait $LMGRD_PID
        EXIT_CODE=$?
        
        log "FlexLM s'est arrêté avec le code: $EXIT_CODE"
        
        # Si arrêt normal, sortir de la boucle
        if [ $EXIT_CODE -eq 0 ]; then
            log "Arrêt normal, sortie du programme"
            break
        fi
    else
        log "ERREUR: Échec du démarrage de FlexLM"
    fi
    
    # Attente avant redémarrage
    log "Redémarrage dans $RESTART_DELAY secondes..."
    sleep $RESTART_DELAY
done

exit 0
