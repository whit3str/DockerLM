FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Création d'un utilisateur non-root avec UID/GID spécifiques
RUN groupadd -r -g 1000 flexlm && useradd -r -g flexlm -u 1000 -d /opt/flexlm -s /bin/bash flexlm

# Installation des dépendances
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nano \
    sudo \
    net-tools \
    dos2unix \
    lsb-core \
    build-essential \
    wget \
    gnupg2 \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/tmp

# Création des répertoires avec permissions appropriées
RUN mkdir -p /opt/flexlm/{logs,bin,licenses,vendors,archive,tmp} && \
    chown -R flexlm:flexlm /opt/flexlm && \
    chmod -R 755 /opt/flexlm

# Copie du script de démarrage
COPY --chown=flexlm:flexlm start-flexlm.sh /opt/flexlm/bin/
COPY --chown=flexlm:flexlm lmgrd /opt/flexlm/bin/
COPY --chown=flexlm:flexlm lmutil /opt/flexlm/bin/

# Correction des permissions
RUN dos2unix /opt/flexlm/bin/start-flexlm.sh && \
    chmod +x /opt/flexlm/bin/start-flexlm.sh && \
    chmod +x /opt/flexlm/bin/lmgrd && \
    chmod +x /opt/flexlm/bin/lmutil

# Variables d'environnement
ENV VENDOR_NAME="" \
    MAX_LOG_SIZE_MB=10 \
    LOG_ROTATION_HOURS=1 \
    TMPDIR=/opt/flexlm/tmp

WORKDIR /opt/flexlm
USER flexlm
EXPOSE 27000

CMD ["/bin/bash", "/opt/flexlm/bin/start-flexlm.sh"]
