# Start Hyprland if it's not already started
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
    if uwsm check may-start; then
        exec uwsm start hyprland.desktop >/dev/null 2>&1
    else
        exec Hyprland >/dev/null 2>&1
    fi
fi

# Suppress the login message
touch ~/.hushlogin