# start-flexlm.sh

# Vérification des fichiers nécessaires
if [ ! -f "/opt/flexlm/licenses/license.dat" ]; then
    echo "ERROR: License file not found!"
    exit 1
fi

if [ ! -f "/opt/flexlm/vendors/${VENDOR_NAME}" ]; then
    echo "ERROR: Vendor daemon not found!"
    exit 1
fi

# Démarrage du serveur FlexLM
echo "Starting FlexLM server..."
/opt/flexlm/bin/lmgrd -c /opt/flexlm/licenses/license.dat -l /opt/flexlm/logs/flexlm.log

# Vérification du démarrage
if [ $? -eq 0 ]; then
    echo "FlexLM server started successfully."
else
    echo "FlexLM server failed to start."
    exit 1
fi

# Surveillance des logs en append
exec tail -f /opt/flexlm/logs/flexlm.log