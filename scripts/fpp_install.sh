#!/bin/bash

# fpp-plugin-advancedstats install script

# Abort on the first failure so a broken step can't leave a half-installed
# plugin behind without a visible error.
set -euo pipefail

BASEDIR=$(dirname "$0")
cd "$BASEDIR"
cd ..
PLUGIN_DIR=$(pwd)

# Default FPPDIR before sourcing. FPP's common derives it from $0 when it is
# unset, which resolves to this plugin's directory rather than the FPP install
# when the installer is run by hand.
FPPDIR="${FPPDIR:-/opt/fpp}"
export FPPDIR

# Source FPP common functions if available. Relax errexit/nounset while
# sourcing so FPP's own script isn't held to this script's strictness.
set +eu
if [ -f "${FPPDIR}/scripts/common" ]; then
    . "${FPPDIR}/scripts/common"
elif [ -f "/opt/fpp/scripts/common" ]; then
    . /opt/fpp/scripts/common
fi
set -eu


# Create log file with proper permissions. The name must match the one every
# writer uses (postStart.sh, preStop.sh, functions.inc.php, mqtt_listener.py,
# callbacks.py) - a case mismatch here provisions a file nothing writes to and
# leaves the real log to be created by an append, without fpp:fpp ownership.
LOG_FILE="/home/fpp/media/logs/fpp-plugin-AdvancedStats.log"

mkdir -p "$(dirname "$LOG_FILE")"

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "Created log file: $LOG_FILE"
fi

# Applied unconditionally: on an upgrade the log usually already exists,
# created by an append rather than by this script.
chown fpp:fpp "$LOG_FILE"
chmod 664 "$LOG_FILE"

# Install Python MQTT client library
echo "Installing Python MQTT library..."
apt-get install -y python3-paho-mqtt > /dev/null 2>&1 || echo "Warning: Could not install python3-paho-mqtt"

# Check if database already exists (upgrade scenario)
DB_PATH="/home/fpp/media/config/plugin.fpp-plugin-AdvancedStats.db"
if [ -f "$DB_PATH" ]; then
    echo "Existing database found - running migrations..."
    php "${PLUGIN_DIR}/migrate_database.php"
else
    echo "No existing database - performing fresh installation..."
fi

# Initialize database (creates tables if they don't exist)
echo "Initializing Advanced Stats database..."
if php "${PLUGIN_DIR}/init_database.php"; then
    echo "Database initialized successfully"
else
    echo "ERROR: Database initialization failed" >&2
    exit 1
fi

# Set restart flag if setSetting function is available
if command -v setSetting &> /dev/null; then
    setSetting restartFlag 1
fi