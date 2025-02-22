FROM ubuntu:24.04

# Création des répertoires nécessaires
RUN mkdir -p /opt/flexlm/logs \
    /opt/flexlm/bin \
    /opt/flexlm/licenses \
    /opt/flexlm/vendors

WORKDIR /opt/flexlm

# Installation des dépendances
RUN apt-get update && \
    apt-get install -y \
    nano \
    sudo \
    net-tools \
    dos2unix \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/tmp

# Copie des fichiers
COPY start-flexlm.sh /opt/flexlm/bin/
COPY binaries/lmgrd /opt/flexlm/bin/
COPY binaries/lmutil /opt/flexlm/bin/

# Correction des fins de ligne et permissions
RUN dos2unix /opt/flexlm/bin/start-flexlm.sh && \
    chmod +x /opt/flexlm/bin/start-flexlm.sh \
    /opt/flexlm/bin/lmgrd \
    /opt/flexlm/bin/lmutil

# Point d'entrée du conteneur
CMD ["/bin/bash", "/opt/flexlm/bin/start-flexlm.sh"]
