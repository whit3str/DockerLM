FROM ubuntu:22.04

# Création d'un utilisateur non-root
RUN groupadd -r flexlm && useradd -r -g flexlm -d /opt/flexlm -s /bin/bash flexlm

# Installation des dépendances en une seule couche
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    nano=6.2-1 \
    sudo=1.9.9-1ubuntu2 \
    net-tools=1.60+git20181103.0eebece-1ubuntu5 \
    dos2unix=7.4.2-2 \
    lsb-core=11.1.0ubuntu4 \
    build-essential=12.9ubuntu3 \
    wget=1.21.2-2ubuntu1 \
    gnupg2=2.2.27-3ubuntu2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /usr/tmp

# Création des répertoires nécessaires avec les bonnes permissions
RUN mkdir -p /opt/flexlm/{logs,bin,licenses,vendors} && \
    chown -R flexlm:flexlm /opt/flexlm

# Copie des binaires et scripts avec l'ordre optimisé pour le cache
COPY binaries/lmgrd binaries/lmutil /opt/flexlm/bin/
COPY start-flexlm.sh /opt/flexlm/bin/

# Correction des fins de ligne et permissions
RUN dos2unix /opt/flexlm/bin/start-flexlm.sh && \
    chmod +x /opt/flexlm/bin/start-flexlm.sh \
             /opt/flexlm/bin/lmgrd \
             /opt/flexlm/bin/lmutil && \
    chown -R flexlm:flexlm /opt/flexlm/bin

# Définir le répertoire de travail
WORKDIR /opt/flexlm

# Passer à l'utilisateur non-root
USER flexlm

# Point d'entrée du conteneur
CMD ["/bin/bash", "/opt/flexlm/bin/start-flexlm.sh"]
