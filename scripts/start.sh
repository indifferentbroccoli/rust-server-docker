#!/bin/bash
# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

# Support both old (RUST_*) and new variable names for backward compatibility
SERVER_NAME=$(get_var "SERVER_NAME" "rustserver")
SERVER_DESCRIPTION=$(get_var "SERVER_DESCRIPTION" "Welcome to your Indifferent Broccoli Rust server")
SERVER_SEED=$(get_var "SERVER_SEED" "12345")
WORLD_SIZE=$(get_var "SERVER_WORLDSIZE" "3500")
MAX_PLAYERS=$(get_var "SERVER_MAXPLAYERS" "50")
SERVER_PORT=$(get_var "SERVER_PORT" "${DEFAULT_PORT:-28015}")
RCON_PORT=$(get_var "RCON_PORT" "28016")
APP_PORT=$(get_var "APP_PORT" "28082")
RCON_PASSWORD=$(get_var "RCON_PASSWORD" "admin")
OXIDE_ENABLED=$(get_var "OXIDE_ENABLED" "false")
GENERATE_SETTINGS=$(get_var "GENERATE_SETTINGS" "true")
SAVE_INTERVAL=$(get_var "SAVE_INTERVAL" "600")
RUST_STARTUP_ARGUMENTS=$(get_var "SERVER_STARTUP_ARGUMENTS" "")

# Configure RCON settings
LogAction "Configuring RCON settings"
cat >/home/steam/server/rcon.yaml  <<EOL
default:
  address: "127.0.0.1:${RCON_PORT}"
  password: "${RCON_PASSWORD}"
EOL

cd /steamcmd/rust || exit

# Build startup arguments
STARTUP_ARGS="-batchmode -load -nographics +server.secure 1"

if [ "$GENERATE_SETTINGS" = "true" ]; then
  LogAction "Configuring server settings"
  
  STARTUP_ARGS="${STARTUP_ARGS} +server.hostname \"${SERVER_NAME}\""
  STARTUP_ARGS="${STARTUP_ARGS} +server.description \"${SERVER_DESCRIPTION}\""
  STARTUP_ARGS="${STARTUP_ARGS} +server.port ${SERVER_PORT}"
  STARTUP_ARGS="${STARTUP_ARGS} +server.queryport ${RCON_PORT}"
  STARTUP_ARGS="${STARTUP_ARGS} +rcon.port ${RCON_PORT}"
  STARTUP_ARGS="${STARTUP_ARGS} +rcon.password \"${RCON_PASSWORD}\""
  STARTUP_ARGS="${STARTUP_ARGS} +rcon.web 1"
  STARTUP_ARGS="${STARTUP_ARGS} +app.port ${APP_PORT}"
  STARTUP_ARGS="${STARTUP_ARGS} +server.maxplayers ${MAX_PLAYERS}"
  STARTUP_ARGS="${STARTUP_ARGS} +server.worldsize ${WORLD_SIZE}"
  STARTUP_ARGS="${STARTUP_ARGS} +server.seed ${SERVER_SEED}"
  STARTUP_ARGS="${STARTUP_ARGS} +server.identity \"${SERVER_NAME}\""
  STARTUP_ARGS="${STARTUP_ARGS} +server.saveinterval ${SAVE_INTERVAL:-600}"
  
  # Update checking
  if [ -n "$SERVER_HEADERIMAGE" ]; then
    STARTUP_ARGS="${STARTUP_ARGS} +server.headerimage \"${SERVER_HEADERIMAGE}\""
  fi
  
  if [ -n "$SERVER_URL" ]; then
    STARTUP_ARGS="${STARTUP_ARGS} +server.url \"${SERVER_URL}\""
  fi
  
  if [ "$PVP" = "false" ]; then
    STARTUP_ARGS="${STARTUP_ARGS} +server.pve true"
  fi
  
  if [ -n "$DECAY_SCALE" ]; then
    STARTUP_ARGS="${STARTUP_ARGS} +decay.scale ${DECAY_SCALE}"
  fi
  
  if [ "$STABILITY" = "false" ]; then
    STARTUP_ARGS="${STARTUP_ARGS} +server.stability false"
  fi
  
  if [ "$RADIATION" = "false" ]; then
    STARTUP_ARGS="${STARTUP_ARGS} +server.radiation false"
  fi
  
elif [ "$GENERATE_SETTINGS" = "false" ]; then
  LogWarn "GENERATE_SETTINGS=false, using existing server configuration"
fi

# Add custom startup arguments if provided
if [ -n "$RUST_STARTUP_ARGUMENTS" ]; then
  LogInfo "Adding custom startup arguments"
  STARTUP_ARGS="${STARTUP_ARGS} ${RUST_STARTUP_ARGUMENTS}"
fi

LogAction "Starting Rust server"
LogInfo "Server: ${SERVER_NAME}"
LogInfo "Port: ${SERVER_PORT}"
LogInfo "RCON Port: ${RCON_PORT}"
LogInfo "App Port: ${APP_PORT}"
LogInfo "Max Players: ${MAX_PLAYERS}"

# Start the server and tail the log file for docker logs
cd /steamcmd/rust || exit

./RustDedicated ${STARTUP_ARGS} -logfile /steamcmd/rust/server-console.txt &

# Wait for log file to be created
while [ ! -f /steamcmd/rust/server-console.txt ]; do
  sleep 1
done

exec tail -f /steamcmd/rust/server-console.txt
