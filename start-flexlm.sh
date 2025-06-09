#!/bin/bash

# Configuration
VENDOR_NAME="${VENDOR_NAME:-}"
LICENSE_PATH="/opt/flexlm/licenses/license.dat"
LOG_FILE="/opt/flexlm/logs/flexlm.log"
VENDOR_DAEMON="/opt/flexlm/vendors/$VENDOR_NAME"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Gestion propre des signaux
cleanup() {
    log "Arrêt du serveur FlexLM..."
    pkill -f lmgrd 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

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

# Démarrage du serveur
log "Démarrage FlexLM avec vendor: $VENDOR_NAME"
mkdir -p "$(dirname "$LOG_FILE")"

/opt/flexlm/bin/lmgrd -c "$LICENSE_PATH" -l "$LOG_FILE" &
LMGRD_PID=$!

# Attente et vérification
sleep 3
if kill -0 $LMGRD_PID 2>/dev/null; then
    log "FlexLM démarré avec succès (PID: $LMGRD_PID)"
    wait $LMGRD_PID
else
    log "ERREUR: Échec du démarrage de FlexLM"
    exit 1
fi
