# Use a common base Linux image
FROM ubuntu:latest

# Set default license file path (can be overridden by LM_LICENSE_FILE in docker-compose)
ENV LM_LICENSE_FILE=/opt/flexlm/licenses/license.dat

# Create necessary directories
RUN mkdir -p /opt/flexlm/bin /opt/flexlm/licenses /opt/flexlm/logs

# Copy FlexLM binaries from the 'binaries' directory in the build context
COPY binaries/lmgrd /opt/flexlm/bin/lmgrd
COPY binaries/lmutil /opt/flexlm/bin/lmutil

# Ensure they are executable
RUN chmod +x /opt/flexlm/bin/lmgrd /opt/flexlm/bin/lmutil

# Copy the entrypoint script
COPY entrypoint.sh /opt/flexlm/entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /opt/flexlm/entrypoint.sh

# Expose the default lmgrd port.
# The vendor daemon port is dynamic or specified in the license file;
# users will need to expose it separately if needed.
EXPOSE 27000

# Set the entrypoint
ENTRYPOINT ["/opt/flexlm/entrypoint.sh"]
