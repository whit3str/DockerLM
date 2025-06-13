# Use a common base Linux image
FROM ubuntu:latest

# Set default license file path (can be overridden by LM_LICENSE_FILE in docker-compose)
ENV LM_LICENSE_FILE=/opt/flexlm/licenses/license.dat

# Create necessary directories
RUN mkdir -p /opt/flexlm/bin /opt/flexlm/licenses /opt/flexlm/logs
RUN mkdir -p /usr/tmp/.flexlm && chmod 777 /usr/tmp/.flexlm

# Copy FlexLM binaries from the 'binaries' directory in the build context
COPY binaries/lmgrd /opt/flexlm/bin/lmgrd
COPY binaries/lmutil /opt/flexlm/bin/lmutil

# Ensure they are executable
RUN chmod +x /opt/flexlm/bin/lmgrd /opt/flexlm/bin/lmutil

# Copy the entrypoint script
COPY simple-entrypoint.sh /opt/flexlm/simple-entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /opt/flexlm/simple-entrypoint.sh

# Expose the default lmgrd port.
# The vendor daemon port is dynamic or specified in the license file;
# users will need to expose it separately if needed.
EXPOSE 27000

# Set the entrypoint
ENTRYPOINT ["/opt/flexlm/simple-entrypoint.sh"]
