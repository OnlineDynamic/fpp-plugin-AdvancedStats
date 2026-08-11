#!/bin/sh

# Advanced Stats Plugin - Post-Start Script
# This script runs after FPP starts

BASEDIR=$(dirname "$0")
cd "$BASEDIR"
cd ..
PLUGIN_DIR=$(pwd)

# Start MQTT listener in background
MQTT_LISTENER="${PLUGIN_DIR}/mqtt_listener.py"
LOG_FILE="/home/fpp/media/logs/fpp-plugin-AdvancedStats.log"
FPP_SETTINGS="/home/fpp/media/settings"

# Read a value out of the FPP settings file (key = "value" format)
fpp_setting() {
    [ -f "$FPP_SETTINGS" ] || return 0
    sed -n "s/^$1[[:space:]]*=[[:space:]]*//p" "$FPP_SETTINGS" | tail -n 1 | tr -d '"'
}

# The listener calls connect() once with no retry, so it has to come up after
# the broker is reachable. Poll the broker socket instead of sleeping a fixed
# interval, and do it in the background so this hook never blocks fppd startup.
wait_for_broker() {
    mqtt_host=$(fpp_setting MQTTHost)
    mqtt_port=$(fpp_setting MQTTPort)
    [ -n "$mqtt_host" ] || mqtt_host="localhost"
    [ -n "$mqtt_port" ] || mqtt_port="1883"

    attempt=0
    while [ "$attempt" -lt 60 ]; do
        if python3 -c 'import socket, sys
s = socket.socket()
s.settimeout(1)
rc = s.connect_ex((sys.argv[1], int(sys.argv[2])))
s.close()
sys.exit(0 if rc == 0 else 1)' "$mqtt_host" "$mqtt_port" 2>/dev/null; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done

    echo "MQTT broker at ${mqtt_host}:${mqtt_port} not reachable after 60s - starting listener anyway"
    return 1
}

# Check if MQTT listener is already running
if pgrep -f "mqtt_listener.py" > /dev/null; then
    echo "MQTT listener already running" >> "$LOG_FILE"
else
    # Make sure the script is executable
    chmod +x "$MQTT_LISTENER"

    # Start the MQTT listener
    echo "Starting Advanced Stats MQTT listener..." >> "$LOG_FILE"
    (
        trap '' HUP
        wait_for_broker
        # Re-check: another postStart may have won the race while we waited
        if pgrep -f "mqtt_listener.py" > /dev/null; then
            echo "MQTT listener already running - not starting a second one"
            exit 0
        fi
        exec python3 "$MQTT_LISTENER"
    ) >> "$LOG_FILE" 2>&1 &

    echo "MQTT listener starting with PID: $! (waiting for broker)" >> "$LOG_FILE"
fi


