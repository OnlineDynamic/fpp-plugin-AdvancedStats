#!/bin/sh

# fpp-plugin-AdvancedStats uninstall script
#
# Reverses every side effect this plugin creates outside its own plugin
# directory. Must be safe to run more than once (all removals are guarded
# or use "rm -f").

PLUGIN="fpp-plugin-AdvancedStats"
CONFIGDIR="/home/fpp/media/config"
LOGDIR="/home/fpp/media/logs"

echo "Uninstalling Advanced Stats Plugin..."

# 1. Stop the MQTT listener started by scripts/postStart.sh.
#    FPP does not run preStop.sh on uninstall, so without this the process
#    keeps running (against a since-deleted script) until the next fppd stop.
if pgrep -f "mqtt_listener.py" >/dev/null 2>&1; then
    echo "Stopping MQTT listener..."
    pkill -f "mqtt_listener.py" 2>/dev/null || true
    sleep 1
    pkill -9 -f "mqtt_listener.py" 2>/dev/null || true
fi

# 2. SQLite database, its journal/WAL sidecars, and any safety-backup copies
#    left in config/ by the restore and empty-database actions.
rm -f "${CONFIGDIR}/plugin.${PLUGIN}.db" \
      "${CONFIGDIR}/plugin.${PLUGIN}.db-journal" \
      "${CONFIGDIR}/plugin.${PLUGIN}.db-wal" \
      "${CONFIGDIR}/plugin.${PLUGIN}.db-shm"
rm -f "${CONFIGDIR}/plugin.${PLUGIN}.db.backup-"*

# 3. Plugin log file. Both the current name and the guideline-compliant
#    plugin-<repoName>.log name are removed so nothing is orphaned.
rm -f "${LOGDIR}/${PLUGIN}.log" \
      "${LOGDIR}/plugin-${PLUGIN}.log"

# 4. Plugin settings file.
rm -f "${CONFIGDIR}/plugin.${PLUGIN}"

# Note: python3-paho-mqtt (installed by fpp_install.sh) is a shared system
# dependency and is intentionally left in place.

echo "Advanced Stats Plugin uninstalled successfully"
