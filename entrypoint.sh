#!/bin/bash
set -e

# V2 Environment Variables
VENDOR_NAME="${VENDOR_NAME:-default_vendor}"
LMGRD_PORT="${LMGRD_PORT:-27000}" # Default lmgrd port
VENDOR_PORT="${VENDOR_PORT:-27001}" # Default vendor daemon port
MAC_ADDRESS="${MAC_ADDRESS:-001122334455}" # Default MAC, remove colons for typical FlexLM hostid
HOSTNAME="${HOSTNAME:-flexlm-server}"
MAX_LOG_SIZE_MB="${MAX_LOG_SIZE_MB:-100}" # Max log size in MB

# Sanitize MAC_ADDRESS for FlexLM (remove colons if present)
CLEAN_MAC_ADDRESS=$(echo "${MAC_ADDRESS}" | sed 's/://g')

# Log file and paths
LOG_FILE="/opt/flexlm/logs/${VENDOR_NAME}.log"
ARCHIVE_DIR="/opt/flexlm/logs/archive"

ORIGINAL_LICENSE_DIR="/opt/flexlm/vendors/${VENDOR_NAME}"
ORIGINAL_LICENSE_FILE="${ORIGINAL_LICENSE_DIR}/${VENDOR_NAME}.lic" # Assuming .lic extension
PROCESSED_LICENSE_DIR="/opt/flexlm/licenses" # Processed licenses go here
PROCESSED_LICENSE_FILE="${PROCESSED_LICENSE_DIR}/processed_${VENDOR_NAME}.lic"

LMGRD_BIN="/opt/flexlm/bin/lmgrd"

# The vendor daemon(s) should be in /opt/flexlm/bin or their path specified in license.dat
# Ensure /opt/flexlm/bin is in PATH (it usually is for root or if sourced by default shell)
export PATH="/opt/flexlm/bin:$PATH"

echo "Processing license for VENDOR: ${VENDOR_NAME}"

if [ ! -f "$ORIGINAL_LICENSE_FILE" ]; then
    echo "ERROR: Original license file not found at $ORIGINAL_LICENSE_FILE"
    echo "Please ensure it is mounted correctly at /opt/flexlm/vendors/${VENDOR_NAME}/${VENDOR_NAME}.lic"
    exit 1
fi

# Create directory for processed licenses if it doesn't exist
mkdir -p "$PROCESSED_LICENSE_DIR"

echo "Copying original license from $ORIGINAL_LICENSE_FILE to $PROCESSED_LICENSE_FILE"
cp "$ORIGINAL_LICENSE_FILE" "$PROCESSED_LICENSE_FILE"
chmod 644 "$PROCESSED_LICENSE_FILE" # Ensure it's writable by sed, then readable by lmgrd

echo "Modifying $PROCESSED_LICENSE_FILE with provided environment variables..."

# Modify SERVER line:
# Example: SERVER oldhost oldmac 12345
# Becomes: SERVER newhost newmac newport
# This sed command tries to replace the first three fields after "SERVER"
# It assumes hostid might be 'ANY' or a specific value.
# It also handles an optional existing port on the SERVER line.
# Using | as delimiter for sed to avoid issues with paths and make it clearer.
sed -i -E "s|^SERVER\s+\S+\s+\S+(\s+\S+)?|SERVER ${HOSTNAME} ${CLEAN_MAC_ADDRESS} ${LMGRD_PORT}|" "$PROCESSED_LICENSE_FILE"
echo "  Updated SERVER line with HOSTNAME=${HOSTNAME}, MAC_ADDRESS=${CLEAN_MAC_ADDRESS}, LMGRD_PORT=${LMGRD_PORT}"

# Modify VENDOR line:
# Example: VENDOR vendorname path/to/daemon PORT=oldport
# Becomes: VENDOR vendorname /opt/flexlm/vendors/VENDOR_NAME/vendordaemon PORT=newport
# This assumes the vendor daemon is named $VENDOR_NAME (e.g., "ansyslmd") and is located in its vendor directory.
# This also assumes the VENDOR line might or might not have options or a PORT= part.
VENDOR_DAEMON_PATH="/opt/flexlm/vendors/${VENDOR_NAME}/${VENDOR_NAME}" # Assuming daemon name matches VENDOR_NAME

# First, ensure the VENDOR line has the correct daemon name and path
sed -i -E "s|^(VENDOR\s+${VENDOR_NAME}\s+)\S+|\1${VENDOR_DAEMON_PATH}|" "$PROCESSED_LICENSE_FILE"

# Now, add or update the PORT= for the VENDOR line.
# If PORT= exists, update it.
if grep -q -E "^VENDOR\s+${VENDOR_NAME}.*PORT=" "$PROCESSED_LICENSE_FILE"; then
    sed -i -E "s|^(VENDOR\s+${VENDOR_NAME}.*PORT=)\S+|\1${VENDOR_PORT}|" "$PROCESSED_LICENSE_FILE"
else # If PORT= does not exist, append it.
    sed -i -E "s|^(VENDOR\s+${VENDOR_NAME}.*)|\1 PORT=${VENDOR_PORT}|" "$PROCESSED_LICENSE_FILE"
fi
echo "  Updated VENDOR line for ${VENDOR_NAME} with DAEMON_PATH=${VENDOR_DAEMON_PATH}, VENDOR_PORT=${VENDOR_PORT}"

echo "License processing complete. Processed license is at $PROCESSED_LICENSE_FILE"

manage_log_rotation() {
    echo "Log rotation enabled for $LOG_FILE. Max size: $MAX_LOG_SIZE_MB MB."
    while true; do
        sleep 60 # Check every 60 seconds

        if [ ! -f "$LOG_FILE" ]; then
            continue # Log file doesn't exist, maybe not created yet or just rotated
        fi

        current_size_kb=$(du -k "$LOG_FILE" | cut -f1)
        max_size_kb=$((MAX_LOG_SIZE_MB * 1024))

        if [ "$current_size_kb" -ge "$max_size_kb" ]; then
            echo "Log file $LOG_FILE reached size limit ($current_size_kb KB / $max_size_kb KB)."
            local timestamp
            timestamp=$(date +%Y%m%d%H%M%S)
            local archived_log_file="${ARCHIVE_DIR}/${VENDOR_NAME}.log.${timestamp}"

            echo "Archiving $LOG_FILE to $archived_log_file"
            mv "$LOG_FILE" "$archived_log_file"

            echo "Creating new log file $LOG_FILE"
            touch "$LOG_FILE"
            chmod 644 "$LOG_FILE" # Ensure lmgrd can write to it

            # Optional: Signal lmgrd to reopen log files.
            # This depends on lmgrd version and vendor daemon behavior.
            # Example: /opt/flexlm/bin/lmutil lmreread -c "$PROCESSED_LICENSE_FILE" -l "$LOG_FILE"
            # For now, we rely on lmgrd to open the new file, or tail -F to follow.
            echo "Log rotation complete. New log file created."
        fi
    done
}

if [ ! -x "$LMGRD_BIN" ]; then
    echo "ERROR: lmgrd not found or not executable at $LMGRD_BIN"
    exit 1
fi

# Create log and archive directories
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$ARCHIVE_DIR"
touch "$LOG_FILE" # Create log file so tail doesn't fail immediately

# Start log rotation in the background
manage_log_rotation &
echo "Log rotation process started in background."

# VENDOR_DAEMON_PATH was already defined and used during license processing.
# For clarity, its value is /opt/flexlm/vendors/${VENDOR_NAME}/${VENDOR_NAME}
echo "Ensuring vendor daemon is executable..."
if [ -f "$VENDOR_DAEMON_PATH" ]; then
    chmod +x "$VENDOR_DAEMON_PATH"
    echo "Vendor daemon $VENDOR_DAEMON_PATH made executable."
else
    echo "WARNING: Vendor daemon $VENDOR_DAEMON_PATH not found. License may not work correctly."
    # Depending on strictness, one might choose to exit here.
fi

# Check if lmgrd binary exists (already here, just ensuring position)
if [ ! -x "$LMGRD_BIN" ]; then
    echo "ERROR: lmgrd not found or not executable at $LMGRD_BIN"
    exit 1
fi

echo "Starting FlexLM server..."
echo "  lmgrd: $LMGRD_BIN"
echo "  License: $PROCESSED_LICENSE_FILE"
echo "  Logs: $LOG_FILE"
echo "  Vendor Daemon: $VENDOR_DAEMON_PATH"
echo "Ensure your vendor daemon is correctly referenced in $PROCESSED_LICENSE_FILE and is executable."

# Start lmgrd. It will fork into the background.
"$LMGRD_BIN" -c "$PROCESSED_LICENSE_FILE" -l "$LOG_FILE"

# Keep container alive by tailing the log.
# Use -F to handle log rotation if an external process replaces the file,
# or if lmgrd itself re-creates the log.
echo "Tailing $LOG_FILE to keep container running..."
exec tail -F "$LOG_FILE"
