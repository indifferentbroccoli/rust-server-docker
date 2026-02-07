#!/bin/bash
# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

LogAction "Set file permissions"

# Default to 1000:1000 if not set (for backward compatibility)
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

usermod -o -u "${PUID}" steam
groupmod -o -g "${PGID}" steam

chown -R steam:steam /steamcmd/rust /home/steam/

cat /branding

if [[ "${UPDATE_ON_START:-true}" == "true" || "${UPDATE_ON_START:-true}" == "1" ]]; then
    install
else
    LogWarn "UPDATE_ON_START is set to false, skipping server update from Steam"
fi

# Install Oxide if enabled
install_oxide

# shellcheck disable=SC2317
term_handler() {
    if ! shutdown_server; then
        # Force kill if graceful shutdown fails
        kill -SIGTERM "$(pidof RustDedicated)"
    fi
    tail --pid="$killpid" -f 2>/dev/null
}

trap 'term_handler' SIGTERM

# Check config for warnings
check_admin_password

# Start the server
./start.sh &

# Process ID of su
killpid="$!"
wait "$killpid"
