#!/bin/bash
set -e

LICENSE_FILE="${LM_LICENSE_FILE:-/opt/flexlm/licenses/license.dat}" # Use env var if set
LOG_FILE="/opt/flexlm/logs/flexlm.log"
LMGRD_BIN="/opt/flexlm/bin/lmgrd"

# The vendor daemon(s) should be in /opt/flexlm/bin or their path specified in license.dat
# Ensure /opt/flexlm/bin is in PATH (it usually is for root or if sourced by default shell)
export PATH="/opt/flexlm/bin:$PATH"

if [ ! -f "$LICENSE_FILE" ]; then
    echo "ERROR: License file not found at $LICENSE_FILE"
    echo "Please mount it correctly or ensure LM_LICENSE_FILE is set."
    exit 1
fi

if [ ! -x "$LMGRD_BIN" ]; then
    echo "ERROR: lmgrd not found or not executable at $LMGRD_BIN"
    exit 1
fi

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE" # Create log file so tail doesn't fail immediately

echo "Starting FlexLM server..."
echo "  lmgrd: $LMGRD_BIN"
echo "  License: $LICENSE_FILE"
echo "  Logs: $LOG_FILE"
echo "Ensure your vendor daemon is in /opt/flexlm/bin/ (copied or mounted) and referenced in $LICENSE_FILE,"
echo "or its full path is specified in $LICENSE_FILE."

# Start lmgrd. It will fork into the background.
"$LMGRD_BIN" -c "$LICENSE_FILE" -l "$LOG_FILE"

# Keep container alive by tailing the log.
# Use -F to handle log rotation if an external process replaces the file,
# or if lmgrd itself re-creates the log.
echo "Tailing $LOG_FILE to keep container running..."
exec tail -F "$LOG_FILE"
