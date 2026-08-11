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


# Self-heal the git origin after the GitHub repo rename
# (OnlineDynamic/Statistics-Fpp-Plugin -> OnlineDynamic/fpp-plugin-AdvancedStats).
#
# The plugin directory name never changed - FPP clones into ${PLUGINDIR}/<repoName>
# and repoName has always been fpp-plugin-AdvancedStats - so there is no data to
# migrate. The only stale artifact in an existing install is origin, which still
# names the old repo and keeps working purely because GitHub redirects renamed
# repos. That redirect vanishes the instant the old name is reclaimed by anyone,
# and old clones would then fail to pull or, worse, silently start pulling from
# whatever repo took the name. Rewrite it here, while the redirect still works,
# so the upgrade path stops depending on it.
#
# FPP runs this script after 'git pull' on every upgrade (upgrade_plugin resolves
# scripts/fpp_install.sh as its post-pull script), so existing installs fix
# themselves on their next upgrade.
#
# Scoped to the exact old owner/repo so forks, SSH remotes and hand-edited
# remotes are left alone, and the path is rewritten in place so an embedded
# GitHub credential (FPP's InjectGitHubCredentials may have put one there at
# clone time) survives. Never fatal: an install must not fail over this.
OLD_REPO_PATH="/OnlineDynamic/Statistics-Fpp-Plugin"
current_origin=$(git -C "$PLUGIN_DIR" remote get-url origin 2>/dev/null || true)

case "$current_origin" in
    https://github.com${OLD_REPO_PATH}|https://github.com${OLD_REPO_PATH}.git|\
    https://*@github.com${OLD_REPO_PATH}|https://*@github.com${OLD_REPO_PATH}.git)
        new_origin="${current_origin%.git}"
        new_origin="${new_origin%${OLD_REPO_PATH}}/OnlineDynamic/fpp-plugin-AdvancedStats.git"

        # Strip any embedded credential before echoing - this output is streamed
        # to the browser and appended to logs/fpp_plugin_manager.log.
        safe_origin=$(echo "$new_origin" | sed -E 's#(https://)[^/@]+@#\1#')

        if git -C "$PLUGIN_DIR" remote set-url origin "$new_origin" 2>/dev/null; then
            echo "Repository was renamed - updated git origin to ${safe_origin}"
            # git rewrote .git/config as root; hand it back so the fpp user's own
            # git operations in the plugin directory keep working.
            chown fpp:fpp "${PLUGIN_DIR}/.git/config" 2>/dev/null || true
        else
            echo "Warning: could not update git origin; still relying on GitHub's rename redirect" >&2
        fi
        ;;
esac


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