#!/bin/bash

# Vérification de la présence de VENDOR_NAME
if [ -z "$VENDOR_NAME" ]; then
    echo "ERROR: VENDOR_NAME environment variable is not set"
    exit 1
fi

# Variables d'environnement avec les chemins standards FlexLM
LICENSE_PATH="/opt/flexlm/licenses/license.dat"
LOG_DIR="/opt/flexlm/logs"
LOG_FILE="$LOG_DIR/flexlm.log"
ARCHIVE_DIR="$LOG_DIR/archive"
MAX_LOG_SIZE_MB=10
VENDOR_PATH="/opt/flexlm/vendors"
VENDOR_DAEMON="$VENDOR_PATH/$VENDOR_NAME"

# Création du répertoire d'archive si nécessaire
mkdir -p "$ARCHIVE_DIR"

# Fonction de rotation des logs
rotate_logs() {
    if [ -f "$LOG_FILE" ]; then
        size_kb=$(du -k "$LOG_FILE" | cut -f1)
        if [ $size_kb -gt $((MAX_LOG_SIZE_MB * 1024)) ]; then
            timestamp=$(date +%Y%m%d_%H%M%S)
            mv "$LOG_FILE" "$ARCHIVE_DIR/flexlm_$timestamp.log"
            gzip "$ARCHIVE_DIR/flexlm_$timestamp.log"
            echo "Log file rotated to $ARCHIVE_DIR/flexlm_$timestamp.log.gz"
        fi
    fi
}

# Vérification et correction du fichier de licence
if [ ! -f "$LICENSE_PATH" ]; then
    echo "ERROR: License file not found at $LICENSE_PATH"
    exit 1
fi

# Vérifie et corrige les chemins dans le fichier de licence
sed -i "s|:[[:space:]]*/opt/flexlm/|/opt/flexlm/|g" "$LICENSE_PATH"
sed -i "s|/opt/flexlm/:/|/opt/flexlm/|g" "$LICENSE_PATH"

if [ ! -f "$VENDOR_DAEMON" ]; then
    echo "ERROR: Vendor daemon $VENDOR_NAME not found at $VENDOR_DAEMON"
    echo "Checking current vendor directory content:"
    ls -la $VENDOR_PATH/
    exit 1
fi

# Vérification des permissions
if [ ! -x "$VENDOR_DAEMON" ]; then
    echo "ERROR: Vendor daemon $VENDOR_NAME is not executable"
    chmod +x "$VENDOR_DAEMON"
fi

# Rotation des logs existants si nécessaire
rotate_logs

# Affichage des chemins pour debug (sans afficher le contenu complet du fichier de licence)
echo "License file: $LICENSE_PATH"
echo "Vendor daemon: $VENDOR_DAEMON"
echo "Log file: $LOG_FILE"

# Démarrage du serveur FlexLM
echo "Starting FlexLM server with vendor $VENDOR_NAME..."
/opt/flexlm/bin/lmgrd -c "$LICENSE_PATH" -l "$LOG_FILE"

# Vérification du démarrage
if [ $? -eq 0 ]; then
    echo "FlexLM server started successfully."
    
    # Attend un peu que les logs soient générés
    sleep 2
    
    # Affiche les dernières lignes du fichier de log
    if [ -f "$LOG_FILE" ]; then
        echo "---- Latest FlexLM log entries ----"
        tail -n 20 "$LOG_FILE"
        echo "---- End of log entries ----"
    else
        echo "Warning: Log file not created yet"
    fi
else
    echo "FlexLM server failed to start."
    exit 1
fi

# Configuration d'une vérification périodique des logs
while true; do
    rotate_logs
    sleep 3600  # Vérification toutes les heures

    # Surveillance du processus lmgrd
    if ! pgrep lmgrd > /dev/null; then
        echo "ERROR: FlexLM server process not found. Restarting..."
        /opt/flexlm/bin/lmgrd -c "$LICENSE_PATH" -l "$LOG_FILE"
    fi
done
