#
#   OpenAsar Installer
#
#   OpenAsar, developed by GooseMod, replaces parts of Discord’s
#   desktop code to improve performance and add features.
#
#   This script is an independent installer created for convenience.
#   I do not own or maintain OpenAsar, and all credit goes to its
#   original developers.
#

#!/bin/bash

set -e
trap 'echo -e ""' EXIT

# font types
BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
INVERT="\e[7m"
RESET="\e[0m"
# font colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
PURPLE="\e[35m"
BLUE="\e[34m"
WHITE="\e[97m"
GRAY="\e[90m"
CYAN="\e[38;5;51m"
LIGHT_GRAY="\e[37m"
DARK_GRAY="\e[30m"
DARK_GREEN="\e[38;5;22m"

# vars
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
OPENASAR_DIR=""
CUSTOM_ASAR_PATH=""

# new line
echo -e ""

# log functions
success() {
    echo -e "   ${BOLD}${DARK_GREEN}[${GREEN}SUCCESS${DARK_GREEN}] ${RESET}$1${RESET}"
}
info() {
    echo -e "      ${BOLD}${BLUE}[${CYAN}INFO${BLUE}] ${RESET}$1${RESET}"
}
error() {
    echo -e "     ${BOLD}${RED}[${RED}ERROR${RED}] ${RESET}${WHITE}${BOLD}$1${RESET}"
}

# main functions

# requires root privileges
require_sudo() {
    if [[ $EUID -ne 0 ]]; then
        error "This script requires sudo privileges. Run with sudo."
        exit 1
    fi
}

# finds discord path
find_discord_installation() {
    # se l’utente ha passato --asar-path, usa quello
    if [[ -n "$CUSTOM_ASAR_PATH" ]]; then
        if [ -f "$CUSTOM_ASAR_PATH" ] && [ -r "$CUSTOM_ASAR_PATH" ]; then
            OPENASAR_DIR="$CUSTOM_ASAR_PATH"
            success "Discord app.asar set to: $OPENASAR_DIR"
            return
        else
            error "Invalid path provided for --asar-path: $CUSTOM_ASAR_PATH. Check permissions and existence."
            exit 1
        fi
    fi


    # app.asar default paths
    APP_ASAR_PATHS=(
        "/opt/discord/resources/app.asar"
        "/usr/lib/discord/resources/app.asar"
        "/usr/lib64/discord/resources/app.asar"
        "/usr/share/discord/resources/app.asar"
        "/var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/app.asar"
        "$HOME/.local/share/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/app.asar"
        "/opt/discord-ptb/resources/app.asar"
        "/usr/lib/discord-ptb/resources/app.asar"
        "/usr/lib64/discord-ptb/resources/app.asar"
        "/usr/share/discord-ptb/resources/app.asar"
        "/var/lib/flatpak/app/com.discordapp.DiscordPtb/current/active/files/discord-ptb/resources/app.asar"
        "$HOME/.local/share/flatpak/app/com.discordapp.DiscordPtb/current/active/files/discordPtb/resources/app.asar"
        "/opt/discord-canary/resources/app.asar"
        "/usr/lib/discord-canary/resources/app.asar"
        "/usr/lib64/discord-canary/resources/app.asar"
        "/usr/share/discord-canary/resources/app.asar"
        "/var/lib/flatpak/app/com.discordapp.DiscordCanary/current/active/files/discord-canary/resources/app.asar"
        "$HOME/.local/share/flatpak/app/com.discordapp.DiscordCanary/current/active/files/discordCanary/resources/app.asar"
    )

    for path in "${APP_ASAR_PATHS[@]}"; do
        if [ -f "$path" ]; then
            OPENASAR_DIR="$path"
            success "Discord app.asar found: $OPENASAR_DIR"
            return
        fi
    done

    info "Verifying app.asar..."
    if [ -z "$OPENASAR_DIR" ]; then
        error "No Discord installation was found."
        error "If you think that this is an error, run:"
        error "    ${RESET}${GREEN}${SCRIPT_PATH} ${YELLOW}--asar-path ${BOLD}[path]"
        exit 1
    fi
}

# kills discord
kill_discord() {
    PIDS=$(pgrep -x Discord || true)
    if [[ -n "$PIDS" ]]; then
        info "Closing Discord..."
        for pid in $PIDS; do
            kill -9 "$pid" || true
        done
        sleep 1
        success "All Discord instances have been closed."
    else
        success "No running Discord instances found."
    fi
}



# installs openasar
install_openasar() {
    # download .asar
    info "Downloading OpenAsar..."
    curl -sSL -o "$HOME/openasar.asar" "https://github.com/GooseMod/OpenAsar/releases/download/nightly/app.asar"
    success "OpenAsar downloaded to $HOME/openasar.asar"

    kill_discord

    # move downloaded file to OPENASAR_DIR
    info "Installing OpenAsar..."
    cp -f "$HOME/openasar.asar" "${OPENASAR_DIR}"
    success "OpenAsar has been successfully installed."
}

# launches discord

launch_discord() {
    info "Launching Discord..."

    DISCORD_BIN="$(dirname "$OPENASAR_DIR")/../Discord"

    if [ -f "$DISCORD_BIN" ]; then
        sudo -u "$SUDO_USER" env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" "$DISCORD_BIN" &>/dev/null &
        success "Discord has been launched."
    else
        error "Discord executable not found at $DISCORD_BIN."
        return 1
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --asar-path)
            shift
            CUSTOM_ASAR_PATH="$1"
            ;;
        *)
            shift
            ;;
    esac
done

require_sudo
find_discord_installation
install_openasar
launch_discord
