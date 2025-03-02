#!/usr/bin/env bash

# Lock file to prevent multiple clicks
LOCK_FILE="/tmp/systemupdate.lock"
WAYBAR_SIGNAL="20"  # Signal to Waybar for updates

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it to use this script." >&2
    exit 1
fi

# Check if Arch Linux
if [ ! -f /etc/arch-release ]; then
    exit 0
fi

# Check if a package is installed
pkg_installed() {
    local pkgIn=$1
    if pacman -Qi "$pkgIn" &> /dev/null; then
        return 0
    elif pacman -Qi "flatpak" &> /dev/null && flatpak info "$pkgIn" &> /dev/null; then
        return 0
    elif command -v "$pkgIn" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Determine AUR helper
get_aurhlpr() {
    if pkg_installed yay; then
        aurhlpr="yay"
    elif pkg_installed paru; then
        aurhlpr="paru"
    else
        aurhlpr=""
    fi
}

# Get AUR helper
get_aurhlpr

# Check if system update is already running in another kitty instance
if [ -f "$LOCK_FILE" ]; then
    echo "System update is already running in another instance."
    exit 1
fi

# Lock the script to prevent multiple executions
touch "$LOCK_FILE"

# Trigger upgrade if "up" argument is passed
if [ "$1" == "up" ]; then
    # Get the monitor where Waybar is focused
    monitor=$(hyprctl activewindow -j | jq -r '.monitor')
    monitor=${monitor:-DP-2}  # Fallback monitor

    # Send "Updating..." message to Waybar
    pkill -RTMIN+20 waybar
    echo "{\"text\":\"Updating...\"}"
    pkill -RTMIN+20 waybar  # Send the signal to Waybar to update the message

    # Actual update process
    command="
    fastfetch
    $0 upgrade
    ${aurhlpr} -Syu
    if pkg_installed flatpak; then
        flatpak update -y
    fi
    read -n 1 -p 'Press any key to continue...'
    "

    # Launch the update process in kitty on the detected monitor
    hyprctl dispatch exec "[monitor:$monitor] kitty --title systemupdate sh -c \"$command\""

    # Remove the lock file to indicate that the update has finished
    rm -f "$LOCK_FILE"

    # Once the update is done, reset Waybar status
    pkill -RTMIN+20 waybar
    echo "{\"text\":\"No updates available\"}"
    pkill -RTMIN+20 waybar
    exit
fi

# Get update counts
aur=0
ofc=0
fpk=0

[ -n "$aurhlpr" ] && aur=$(${aurhlpr} -Qua 2>/dev/null | wc -l)
[ -x "$(command -v checkupdates)" ] && ofc=$(checkupdates 2>/dev/null | wc -l)
[ -x "$(command -v flatpak)" ] && fpk=$(flatpak remote-ls --updates 2>/dev/null | wc -l)

# Calculate total updates
upd=$((ofc + aur + fpk))

# Output updates status for Waybar
if [ "$upd" -eq 0 ]; then
    # No updates available, reset Waybar
    echo "{\"text\":\"No updates available\"}"
else
    # Updates are available, show in Waybar
    echo "{\"text\":\" Updates $upd\", \"tooltip\":\"Official $ofc\nAUR $aur\nFlatpak $fpk\", \"on-click\":\"systemupdate.sh up\"}"
fi