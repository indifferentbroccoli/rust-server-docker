#!/bin/bash

#================
# Variable Helper
#================
# Handles both RUST_* prefixed and clean variable names for backward compatibility from Didstopia's image.
get_var() {
  local var_name="$1"
  local default="$2"
  local rust_var="RUST_${var_name}"
  echo "${!rust_var:-${!var_name:-$default}}"
}

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
  
  if [ -f /home/steam/server/rcon.yaml ]; then
    LogInfo "Sending save and quit command via RCON"
    rcon-cli --config /home/steam/server/rcon.yaml "save"
    sleep 2
    rcon-cli --config /home/steam/server/rcon.yaml "quit"
    
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
  local OXIDE_CHECK=$(get_var "OXIDE_ENABLED" "false")
  
  if [[ "$OXIDE_CHECK" == "true" || "$OXIDE_CHECK" == "1" ]]; then
    LogAction "Installing Oxide/uMod"
    
    cd /steamcmd/rust || exit
    
    # Download and extract latest Oxide using curl and bsdtar
    OXIDE_URL="https://umod.org/games/rust/download/develop"
    LogInfo "Downloading Oxide from: $OXIDE_URL"
    if curl -sL "$OXIDE_URL" | bsdtar -xvf- -C /steamcmd/rust/ 2>&1 | head -20; then
      chmod 755 /steamcmd/rust/CSharpCompiler.x86_x64 > /dev/null 2>&1 || true
      LogSuccess "Oxide installed successfully"
      LogInfo "Oxide files extracted to /steamcmd/rust/"
      ls -la /steamcmd/rust/ | grep -i "oxide\|csharp" || true
    else
      LogError "Failed to download or extract Oxide"
      return 1
    fi
  fi
}
