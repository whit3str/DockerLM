<<<<<<< HEAD
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
=======
FROM ubuntu:22.04

# Variables d'environnement
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Installation des dépendances essentielles en une seule couche
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dos2unix \
    procps \
    net-tools \
    iproute2 \
    iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Création de l'utilisateur et des répertoires
RUN groupadd -r flexlm && \
    useradd -r -g flexlm -d /opt/flexlm flexlm && \
    mkdir -p /opt/flexlm/{bin,logs,licenses,vendors,tmp,config} && \
    chown -R flexlm:flexlm /opt/flexlm

# Copie des binaires FlexLM
COPY binaries/lmgrd binaries/lmutil /opt/flexlm/bin/
RUN chmod +x /opt/flexlm/bin/lmgrd /opt/flexlm/bin/lmutil && \
    chown flexlm:flexlm /opt/flexlm/bin/lmgrd /opt/flexlm/bin/lmutil

# Copie et configuration du script
COPY start-flexlm.sh /opt/flexlm/bin/
RUN dos2unix /opt/flexlm/bin/start-flexlm.sh && \
    chmod +x /opt/flexlm/bin/start-flexlm.sh && \
    chown flexlm:flexlm /opt/flexlm/bin/start-flexlm.sh

# Configuration par défaut
ENV VENDOR_NAME="" \
    TMPDIR=/opt/flexlm/tmp

WORKDIR /opt/flexlm
USER flexlm
EXPOSE 27000-27001

>>>>>>> 846a1942677cc755eb8472c27a817ed2290a49e9
CMD ["/bin/bash", "/opt/flexlm/bin/start-flexlm.sh"]
