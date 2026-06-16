#!/bin/bash
# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

# Support both old (RUST_*) and new variable names for backward compatibility
SERVER_NAME=$(get_var "SERVER_NAME" "rustserver")
SERVER_DESCRIPTION=$(get_var "SERVER_DESCRIPTION" "Welcome to your Indifferent Broccoli Rust server")
SERVER_SEED=$(get_var "SERVER_SEED" "12345")
WORLD_SIZE=$(get_var "WORLD_SIZE" "3500")
MAX_PLAYERS=$(get_var "MAX_PLAYERS" "50")
SERVER_PORT=$(get_var "SERVER_PORT" "${DEFAULT_PORT:-28015}")
RCON_PORT=$(get_var "RCON_PORT" "28016")
APP_PORT=$(get_var "APP_PORT" "28082")
RCON_PASSWORD=$(get_var "RCON_PASSWORD" "admin")
OXIDE_ENABLED=$(get_var "OXIDE_ENABLED" "false")
GENERATE_SETTINGS=$(get_var "GENERATE_SETTINGS" "true")
SAVE_INTERVAL=$(get_var "SAVE_INTERVAL" "600")
STARTUP_ARGUMENTS=$(get_var "STARTUP_ARGUMENTS" "")
SERVER_IDENTITY=$(get_var "SERVER_IDENTITY" "${SERVER_NAME}")
SERVER_TAGS=$(get_var "SERVER_TAGS" "")
SERVER_LOGOIMAGE=$(get_var "SERVER_LOGOIMAGE" "")
MAP_TYPE=$(get_var "MAP_TYPE" "Procedural Map")
CUSTOM_MAP_URL=$(get_var "CUSTOM_MAP_URL" "")
GAME_MODE=$(get_var "GAME_MODE" "standard")
MAX_TEAM_SIZE=$(get_var "MAX_TEAM_SIZE" "")
SERVER_ERA=$(get_var "SERVER_ERA" "")
EAC_ENABLED=$(get_var "EAC_ENABLED" "true")
SERVER_SECURE=$(get_var "SERVER_SECURE" "1")
SERVER_ENCRYPTION=$(get_var "SERVER_ENCRYPTION" "2")

# Configure RCON settings
LogAction "Configuring RCON settings"
cat >/home/steam/server/rcon.yaml  <<EOL
default:
  address: "127.0.0.1:${RCON_PORT}"
  password: "${RCON_PASSWORD}"
  type: "web"
EOL

cd /steamcmd/rust || exit

# Build startup arguments using array
ARGS=(-batchmode -load -nographics +server.secure "${SERVER_SECURE}")

if [ "$GENERATE_SETTINGS" = "true" ]; then
  LogAction "Configuring server settings"

  ARGS+=(+server.hostname "${SERVER_NAME}")
  ARGS+=(+server.description "${SERVER_DESCRIPTION}")
  ARGS+=(+server.port "${SERVER_PORT}")
  ARGS+=(+server.queryport "${RCON_PORT}")
  ARGS+=(+rcon.port "${RCON_PORT}")
  ARGS+=(+rcon.password "${RCON_PASSWORD}")
  ARGS+=(+rcon.web 1)
  ARGS+=(+app.port "${APP_PORT}")
  ARGS+=(+server.maxplayers "${MAX_PLAYERS}")
  ARGS+=(+server.worldsize "${WORLD_SIZE}")
  ARGS+=(+server.seed "${SERVER_SEED}")
  ARGS+=(+server.identity "${SERVER_IDENTITY}")
  ARGS+=(+server.saveinterval "${SAVE_INTERVAL:-600}")
  ARGS+=(+server.encryption "${SERVER_ENCRYPTION}")

  if [ -n "$CUSTOM_MAP_URL" ]; then
    ARGS+=(+server.levelurl "${CUSTOM_MAP_URL}")
  else
    ARGS+=(+server.level "${MAP_TYPE}")
  fi

  if [ -n "$GAME_MODE" ] && [ "$GAME_MODE" != "standard" ]; then
    ARGS+=(+server.gamemode "${GAME_MODE}")
  fi

  if [ -n "$MAX_TEAM_SIZE" ]; then
    ARGS+=(+server.maxteamsize "${MAX_TEAM_SIZE}")
  fi

  if [ -n "$SERVER_ERA" ]; then
    ARGS+=(+server.era "${SERVER_ERA}")
  fi

  if [ -n "$SERVER_TAGS" ]; then
    ARGS+=(+server.tags "${SERVER_TAGS}")
  fi

  if [ -n "$SERVER_HEADERIMAGE" ]; then
    ARGS+=(+server.headerimage "${SERVER_HEADERIMAGE}")
  fi

  if [ -n "$SERVER_LOGOIMAGE" ]; then
    ARGS+=(+server.logoimage "${SERVER_LOGOIMAGE}")
  fi

  if [ -n "$SERVER_URL" ]; then
    ARGS+=(+server.url "${SERVER_URL}")
  fi

  if [ "$PVP" = "false" ]; then
    ARGS+=(+server.pve true)
  fi

  if [ -n "$DECAY_SCALE" ]; then
    ARGS+=(+decay.scale "${DECAY_SCALE}")
  fi

  if [ "$STABILITY" = "false" ]; then
    ARGS+=(+server.stability false)
  fi

  if [ "$RADIATION" = "false" ]; then
    ARGS+=(+server.radiation false)
  fi

elif [ "$GENERATE_SETTINGS" = "false" ]; then
  LogWarn "GENERATE_SETTINGS=false, using existing server configuration"
fi

# Add custom startup arguments if provided
if [ -n "$STARTUP_ARGUMENTS" ]; then
  LogInfo "Adding custom startup arguments"
  ARGS+=(${STARTUP_ARGUMENTS})
fi

LogAction "Starting Rust server"
LogInfo "Server: ${SERVER_NAME}"
LogInfo "Port: ${SERVER_PORT}"
LogInfo "RCON Port: ${RCON_PORT}"
LogInfo "App Port: ${APP_PORT}"
LogInfo "Max Players: ${MAX_PLAYERS}"
LogInfo "Map Type: ${MAP_TYPE}"
LogInfo "Game Mode: ${GAME_MODE}"
LogInfo "Server Secure: ${SERVER_SECURE}"
LogInfo "Encryption: ${SERVER_ENCRYPTION}"

# Start the server and tail the log file for docker logs
cd /steamcmd/rust || exit

./RustDedicated "${ARGS[@]}" -logfile /steamcmd/rust/server-console.txt &

# Wait for log file to be created
while [ ! -f /steamcmd/rust/server-console.txt ]; do
  sleep 1
done

exec tail -f /steamcmd/rust/server-console.txt
