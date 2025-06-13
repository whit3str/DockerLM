#!/bin/bash
set -e

# V2 Environment Variables (simplified for direct license use)
VENDOR_NAME="${VENDOR_NAME:-default_vendor}"
MAX_LOG_SIZE_MB="${MAX_LOG_SIZE_MB:-100}" # Max log size in MB

# Log file and paths
LOG_FILE="/opt/flexlm/logs/${VENDOR_NAME}.log"
ARCHIVE_DIR="/opt/flexlm/logs/archive"

# Define VENDOR_DAEMON_PATH early for consistent use
VENDOR_DAEMON_PATH="/opt/flexlm/vendors/${VENDOR_NAME}" # Path to the vendor daemon executable

ORIGINAL_LICENSE_FILE="/opt/flexlm/licenses/license.dat" # Static path for input license

LMGRD_BIN="/opt/flexlm/bin/lmgrd"

# The vendor daemon(s) should be in /opt/flexlm/bin or their path specified in license.dat
# Ensure /opt/flexlm/bin is in PATH (it usually is for root or if sourced by default shell)
export PATH="/opt/flexlm/bin:$PATH"

# Check for license file
if [ ! -f "$ORIGINAL_LICENSE_FILE" ]; then
    echo "ERROR: License file not found at $ORIGINAL_LICENSE_FILE"
    echo "Please ensure your license.dat is mounted correctly to $ORIGINAL_LICENSE_FILE and is pre-configured for this environment."
    exit 1
fi

# License file is used directly, no processing, copying, or modification steps needed.
echo "Using license file directly: $ORIGINAL_LICENSE_FILE"

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

# VENDOR_DAEMON_PATH is already defined with the new path /opt/flexlm/vendors/${VENDOR_NAME}
echo "Ensuring vendor daemon (${VENDOR_DAEMON_PATH}) is executable..."
if [ -f "$VENDOR_DAEMON_PATH" ]; then # Corrected variable name from VENDOR_DAEMONS_PATH
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
echo "  License: $ORIGINAL_LICENSE_FILE (used directly)"
echo "  Logs: $LOG_FILE"
echo "  Vendor Daemon: $VENDOR_DAEMON_PATH"
echo "Ensure your license.dat is correctly pre-configured for this environment."
echo "The VENDOR line in license.dat should point to $VENDOR_DAEMON_PATH and specify any required vendor port."
echo "The SERVER line in license.dat should specify the correct hostname and lmgrd port if not default."

# Start lmgrd. It will fork into the background.
"$LMGRD_BIN" -c "$ORIGINAL_LICENSE_FILE" -l "$LOG_FILE"

# Keep container alive by tailing the log.
# Use -F to handle log rotation if an external process replaces the file,
# or if lmgrd itself re-creates the log.
echo "Tailing $LOG_FILE to keep container running..."
exec tail -F "$LOG_FILE"
