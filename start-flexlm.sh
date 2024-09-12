#!/bin/bash

# Démarrer le serveur FlexLM
echo "Starting FlexLM server..."
./lmgrd -c license.dat -l license.log

# Vérifier si le serveur a démarré correctement
if [ $? -eq 0 ]; then
    echo "FlexLM server started successfully."
else
    echo "FlexLM server failed to start."
    exit 1
fi

# Garder le conteneur en cours d'exécution
tail -f license.log