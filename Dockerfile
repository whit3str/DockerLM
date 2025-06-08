FROM ubuntu:22.04

# Variables d'environnement pour éviter les interactions
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Création d'un utilisateur non-root
RUN groupadd -r flexlm && useradd -r -g flexlm -d /opt/flexlm -s /bin/bash flexlm

# Installation des dépendances en une seule couche
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nano=6.2-1 \
    sudo=1.9.9-1ubuntu2 \
    net-tools=1.60+git20181103.0eebece-1ubuntu5 \
    dos2unix=7.4.2-2 \
    lsb-core=11.1.0ubuntu4 \
    build-essential=12.9ubuntu3 \
    wget=1.21.2-2ubuntu1 \
    gnupg2=2.2.27-3ubuntu2 \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/tmp

# Création des répertoires nécessaires avec les bonnes permissions
RUN mkdir -p /opt/flexlm/{logs,bin,licenses,vendors,archive} && \
    chown -R flexlm:flexlm /opt/flexlm

# Copie des binaries et scripts avec l'ordre optimisé pour le cache
COPY --chown=flexlm:flexlm binaries/lmgrd binaries/lmutil /opt/flexlm/bin/
COPY --chown=flexlm:flexlm start-flexlm.sh /opt/flexlm/bin/

# Correction des fins de ligne et permissions
RUN dos2unix /opt/flexlm/bin/start-flexlm.sh && \
    chmod +x /opt/flexlm/bin/start-flexlm.sh \
             /opt/flexlm/bin/lmgrd \
             /opt/flexlm/bin/lmutil

# Variables d'environnement par défaut
ENV VENDOR_NAME="" \
    MAX_LOG_SIZE_MB=10 \
    LOG_ROTATION_HOURS=1

# Healthcheck pour vérifier que le service fonctionne
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /opt/flexlm/bin/lmutil lmstat -c /opt/flexlm/licenses/license.dat -a > /dev/null 2>&1 || exit 1

# Définir le répertoire de travail
WORKDIR /opt/flexlm

# Passer à l'utilisateur non-root
USER flexlm

# Exposition du port par défaut (configurable)
EXPOSE 27000

# Point d'entrée du conteneur
CMD ["/bin/bash", "/opt/flexlm/bin/start-flexlm.sh"]