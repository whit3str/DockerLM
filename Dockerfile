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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Création de l'utilisateur et des répertoires
RUN groupadd -r flexlm && \
    useradd -r -g flexlm -d /opt/flexlm flexlm && \
    mkdir -p /opt/flexlm/{bin,logs,tmp} && \
    chown -R flexlm:flexlm /opt/flexlm

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
EXPOSE 27000

CMD ["/bin/bash", "/opt/flexlm/bin/start-flexlm.sh"]
