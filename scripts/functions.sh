#!/bin/bash

#================
# Log Definitions
#================
export LINE='\n'                        # Line Break
export RESET='\033[0m'                  # Text Reset
export WhiteText='\033[0;37m'           # White

# Bold
export RedBoldText='\033[1;31m'         # Red
export GreenBoldText='\033[1;32m'       # Green
export YellowBoldText='\033[1;33m'      # Yellow
export CyanBoldText='\033[1;36m'        # Cyan
#================
# End Log Definitions
#================

LogInfo() {
  Log "$1" "$WhiteText"
}
LogWarn() {
  Log "$1" "$YellowBoldText"
}
LogError() {
  Log "$1" "$RedBoldText"
}
LogSuccess() {
  Log "$1" "$GreenBoldText"
}
LogAction() {
  Log "$1" "$CyanBoldText" "====" "===="
}
Log() {
  local message="$1"
  local color="$2"
  local prefix="$3"
  local suffix="$4"
  printf "$color%s$RESET$LINE" "$prefix$message$suffix"
}

install() {
  LogAction "Starting Rust server install"
  
  # Install Rust server via SteamCMD
  LogInfo "Installing Rust Dedicated Server (App ID: 258550)"
  
  if ! /home/steam/steamcmd/steamcmd.sh \
    +force_install_dir /steamcmd/rust \
    +login anonymous \
    +app_update 258550 validate \
    +quit; then
    LogError "Failed to install Rust server"
    exit 1
  fi
  
  LogSuccess "Server installation complete"
}

shutdown_server() {
  LogAction "Shutting down Rust server"
  
  if [ -f /home/steam/server/rcon.yml ]; then
    LogInfo "Sending save and quit command via RCON"
    rcon-cli "save"
    sleep 2
    rcon-cli "quit"
    
    # Wait for graceful shutdown
    for i in {1..30}; do
      if ! pgrep "RustDedicated" > /dev/null; then
        LogSuccess "Server shut down gracefully"
        return 0
      fi
      sleep 1
    done
    
    LogWarn "Server did not shut down gracefully, forcing shutdown"
    return 1
  else
    LogWarn "RCON not configured, cannot send shutdown command"
    return 1
  fi
}

check_admin_password() {
  if [ "$ADMIN_PASSWORD" = "admin" ]; then
    LogWarn "WARNING: Admin password is set to default value 'admin'"
    LogWarn "Please change ADMIN_PASSWORD in your .env file for security"
  fi
  
  if [ "$RCON_PASSWORD" = "admin" ]; then
    LogWarn "WARNING: RCON password is set to default value 'admin'"
    LogWarn "Please change RCON_PASSWORD in your .env file for security"
  fi
}

install_oxide() {
  if [ "$OXIDE_ENABLED" = "true" ]; then
    LogAction "Installing Oxide/uMod"
    
    cd /steamcmd/rust || exit
    
    # Download latest Oxide
    if wget -q https://umod.org/games/rust/download -O oxide.zip; then
      unzip -o oxide.zip
      rm oxide.zip
      LogSuccess "Oxide installed successfully"
    else
      LogError "Failed to download Oxide"
    fi
  fi
}
