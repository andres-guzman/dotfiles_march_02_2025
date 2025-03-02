# #!/bin/bash

# # Check if SwayOSD is installed
# use_swayosd=false
# if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null; then
#     use_swayosd=true
# fi

# # Fallback notification function
# fallback_notify() {
#     notify-send -a "VolumeControl" -r 91190 -t 800 "$1" "$2"
# }

# # Get active audio and mic sources
# get_active_output() {
#     pactl info | grep "Default Sink" | awk -F ': ' '{print $2}'
# }

# get_active_input() {
#     pactl info | grep "Default Source" | awk -F ': ' '{print $2}'
# }

# # Get the friendly device name for the current output/input
# get_friendly_device_name() {
#     pactl list sinks | grep -A 10 "Name: $(get_active_output)" | grep "Description" | awk -F ': ' '{print $2}' | sed 's/^[ \t]*//'
# }

# # Define functions

# print_usage() {
#     cat <<EOF
# Usage: $(basename "$0") -[device] <action> [step]

# Devices/Actions:
#     -i    Input device
#     -o    Output device
#     -p    Player application
#     -s    Select output device
#     -t    Toggle to next output device

# Actions:
#     i     Increase volume
#     d     Decrease volume
#     m     Toggle mute

# Optional:
#     step  Volume change step (default: 5)

# Examples:
#     $(basename "$0") -o i 1     # Increase output volume by 1
#     $(basename "$0") -i m       # Toggle input mute
#     $(basename "$0") -p spotify d 1  # Decrease Spotify volume by 1
#     $(basename "$0") -p '' d 1  # Decrease volume by 10 for all players

# EOF
#     exit 1
# }

# notify() {
#     local title="$1" message="$2" icon="$3"
#     if $use_swayosd; then
#         swayosd-client --icon "$icon" --text "$title: $message"
#     else
#         fallback_notify "$title" "$message"
#     fi
# }

# notify_vol() {
#     vol=$(pamixer "$srce" --get-volume)
#     angle=$((vol / 5 * 5))  # Fix the period problem, rounding the volume
#     bar=$(printf '%.0s.' $(seq 1 $(($vol / 15))))
#     output_device=$(get_active_output)
#     device_name=$(get_friendly_device_name)  # Get the friendly output device name
#     # Send notification with device name and volume level separately
#     notify "Volume" "Device: $device_name\nLevel: ${vol}%" ""
# }

# notify_mute() {
#     mute=$(pamixer "$srce" --get-mute)
#     active_device=$([ "$srce" = "--default-source" ] && get_active_input || get_active_output)
#     device_name=$(get_friendly_device_name)  # Get the friendly device name for mute/unmute notifications
#     if [ "$mute" = "true" ]; then
#         notify "Muted" "Device: $device_name\nMuted" ""
#     else
#         notify_vol
#     fi
# }

# change_volume() {
#     local action=$1 step=$2 device=$3 delta="-" mode="--output-volume"

#     [ "$action" = "i" ] && delta="+"
#     [ "$srce" = "--default-source" ] && mode="--input-volume"
#     case $device in
#         "pamixer")
#             $use_swayosd && swayosd-client ${mode} "${delta}${step}" && exit 0
#             pamixer $srce -"$action" "$step"
#             ;;
#         "playerctl")
#             playerctl --player="$srce" volume "$(awk -v step="$step" 'BEGIN {print step/100}')${delta}"
#             ;;
#     esac
#     notify_vol
# }

# toggle_mute() {
#     local device=$1 mode="--output-volume"
#     [ "$srce" = "--default-source" ] && mode="--input-volume"
#     case $device in
#         "pamixer")
#             $use_swayosd && swayosd-client "${mode}" mute-toggle && exit 0
#             pamixer $srce -t
#             ;;
#         "playerctl")
#             local volume_file="/tmp/$(basename "$0")_last_volume_${srce:-all}"
#             current_vol=$(playerctl --player="$srce" volume | awk '{ printf "%.2f", $0 }')
#             if [ "$current_vol" != "0.00" ]; then
#                 echo "$current_vol" > "$volume_file"
#                 playerctl --player="$srce" volume 0
#             else
#                 playerctl --player="$srce" volume "$(cat "$volume_file" 2>/dev/null || echo 0.1)"
#             fi
#             ;;
#     esac
#     notify_mute
# }

# select_output() {
#     local selection=$1
#     if [ -n "$selection" ]; then
#         device=$(pactl list sinks | grep -C2 -F "Description: $selection" | grep Name | cut -d: -f2 | xargs)
#         if pactl set-default-sink "$device"; then
#             notify "Activated" "$selection" ""
#         else
#             notify "Error" "Error activating $selection" ""
#         fi
#     else
#         pactl list sinks | grep -ie "Description:" | awk -F ': ' '{print $2}' | sort
#     fi
# }

# toggle_output() {
#     local sink_array default_sink next_sink
#     default_sink=$(get_active_output)
#     mapfile -t sink_array < <(select_output)
#     for i in "${!sink_array[@]}"; do
#         if [[ "${sink_array[i]}" == "$default_sink" ]]; then
#             next_sink="${sink_array[(i+1) % ${#sink_array[@]}]}"
#             break
#         fi
#     done
#     select_output "$next_sink"
# }

# # Main script logic

# # Set default variables
# icodir="${confDir}/dunst/icons/vol"
# step=1

# # Parse options
# while getopts "iop:st" opt; do
#     case $opt in
#         i) device="pamixer"; srce="--default-source"; nsink=$(get_active_input) ;;
#         o) device="pamixer"; srce=""; nsink=$(get_active_output) ;;
#         p) device="playerctl"; srce="$OPTARG"; nsink=$(playerctl --list-all | grep -w "$srce") ;;
#         s) select_output "$(select_output | rofi -dmenu -config "${confDir}/rofi/notification.rasi")"; exit ;;
#         t) toggle_output; exit ;;
#         *) print_usage ;;
#     esac
# done

# shift $((OPTIND-1))

# # Check if device is set
# [ -z "$device" ] && print_usage

# # Execute action
# case $1 in
#     i|d) change_volume "$1" "${2:-$step}" "$device" ;;
#     m) toggle_mute "$device" ;;
#     *) print_usage ;;
# esac


# #!/bin/bash

# # Check if SwayOSD is installed
# use_swayosd=false
# if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null; then
#     use_swayosd=true
# fi

# # Fallback notification function
# fallback_notify() {
#     notify-send -a "VolumeControl" -r 91190 -t 800 "$1" "$2"
# }

# # Get active audio and mic sources
# get_active_output() {
#     pactl info | grep "Default Sink" | awk -F ': ' '{print $2}'
# }

# get_active_input() {
#     pactl info | grep "Default Source" | awk -F ': ' '{print $2}'
# }

# # Get the friendly device name for the current output/input
# get_friendly_device_name() {
#     pactl list sinks | grep -A 10 "Name: $(get_active_output)" | grep "Description" | awk -F ': ' '{print $2}' | sed 's/^[ \t]*//'
# }

# # Define functions
# notify() {
#     local title="$1" message="$2" icon="$3"
#     if $use_swayosd; then
#         swayosd-client --icon "$icon" --text "$title: $message"
#     else
#         fallback_notify "$title" "$message"
#     fi
# }

# notify_vol() {
#     vol=$(pamixer "$srce" --get-volume)
#     angle=$((vol / 5 * 5))  # Fix the period problem, rounding the volume
#     bar=$(printf '%.0s.' $(seq 1 $(($vol / 15))))
#     output_device=$(get_active_output)
#     device_name=$(get_friendly_device_name)  # Get the friendly output device name
#     # Send notification with device name and volume level separately
#     notify "Volume" "Device: $device_name\nLevel: ${vol}%" ""
# }

# notify_mute() {
#     mute=$(pamixer "$srce" --get-mute)
#     active_device=$([ "$srce" = "--default-source" ] && get_active_input || get_active_output)
#     device_name=$(get_friendly_device_name)  # Get the friendly device name for mute/unmute notifications
#     if [ "$mute" = "true" ]; then
#         notify "Muted" "Device: $device_name\nMuted" ""
#     else
#         notify_vol
#     fi
# }

# change_volume() {
#     local action=$1 step=$2 device=$3 delta="-" mode="--output-volume"

#     [ "$action" = "i" ] && delta="+"
#     [ "$srce" = "--default-source" ] && mode="--input-volume"
#     case $device in
#         "pamixer")
#             $use_swayosd && swayosd-client ${mode} "${delta}${step}" && exit 0
#             pamixer $srce -"$action" "$step"
#             ;;
#         "playerctl")
#             playerctl --player="$srce" volume "$(awk -v step="$step" 'BEGIN {print step/100}')${delta}"
#             ;;
#     esac
#     notify_vol
# }

# toggle_mute() {
#     local device=$1 mode="--output-volume"
#     [ "$srce" = "--default-source" ] && mode="--input-volume"
#     case $device in
#         "pamixer")
#             # Toggle mute and update the state accordingly
#             $use_swayosd && swayosd-client "${mode}" mute-toggle && exit 0
#             pamixer $srce -t
#             ;;
#         "playerctl")
#             local volume_file="/tmp/$(basename "$0")_last_volume_${srce:-all}"
#             current_vol=$(playerctl --player="$srce" volume | awk '{ printf "%.2f", $0 }')
#             if [ "$current_vol" != "0.00" ]; then
#                 echo "$current_vol" > "$volume_file"
#                 playerctl --player="$srce" volume 0
#             else
#                 playerctl --player="$srce" volume "$(cat "$volume_file" 2>/dev/null || echo 0.1)"
#             fi
#             ;;
#     esac
#     notify_mute
# }

# select_output() {
#     local selection=$1
#     if [ -n "$selection" ]; then
#         device=$(pactl list sinks | grep -C2 -F "Description: $selection" | grep Name | cut -d: -f2 | xargs)
#         if pactl set-default-sink "$device"; then
#             notify "Activated" "$selection" ""
#         else
#             notify "Error" "Error activating $selection" ""
#         fi
#     else
#         pactl list sinks | grep -ie "Description:" | awk -F ': ' '{print $2}' | sort
#     fi
# }

# toggle_output() {
#     local sink_array default_sink next_sink
#     default_sink=$(get_active_output)
#     mapfile -t sink_array < <(select_output)
#     for i in "${!sink_array[@]}"; do
#         if [[ "${sink_array[i]}" == "$default_sink" ]]; then
#             next_sink="${sink_array[(i+1) % ${#sink_array[@]}]}"
#             break
#         fi
#     done
#     select_output "$next_sink"
# }

# # Main script logic

# # Set default variables
# icodir="${confDir}/dunst/icons/vol"
# step=1

# # Parse options
# while getopts "iop:st" opt; do
#     case $opt in
#         i) device="pamixer"; srce="--default-source"; nsink=$(get_active_input) ;;
#         o) device="pamixer"; srce=""; nsink=$(get_active_output) ;;
#         p) device="playerctl"; srce="$OPTARG"; nsink=$(playerctl --list-all | grep -w "$srce") ;;
#         s) select_output "$(select_output | rofi -dmenu -config "${confDir}/rofi/notification.rasi")"; exit ;;
#         t) toggle_output; exit ;;
#         *) print_usage ;;
#     esac
# done

# shift $((OPTIND-1))

# # Check if device is set
# [ -z "$device" ] && print_usage

# # Execute action
# case $1 in
#     i|d) change_volume "$1" "${2:-$step}" "$device" ;;
#     m) toggle_mute "$device" ;;
#     *) print_usage ;;
# esac


#!/bin/bash

# Check if SwayOSD is installed
use_swayosd=false
if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null; then
    use_swayosd=true
fi

# Fallback notification function
fallback_notify() {
    notify-send -a "VolumeControl" -r 91190 -t 800 "$1" "$2"
}

# Get active audio and mic sources
get_active_output() {
    pactl info | grep "Default Sink" | awk -F ': ' '{print $2}'
}

get_active_input() {
    pactl info | grep "Default Source" | awk -F ': ' '{print $2}'
}

# Get the friendly device name for the current output/input
get_friendly_device_name() {
    pactl list sinks | grep -A 10 "Name: $(get_active_output)" | grep "Description" | awk -F ': ' '{print $2}' | sed 's/^[ \t]*//'
}

# Define functions
notify() {
    local title="$1" message="$2" icon="$3"
    if $use_swayosd; then
        swayosd-client --icon "$icon" --text "$title: $message"
    else
        fallback_notify "$title" "$message"
    fi
}

notify_vol() {
    vol=$(pamixer "$srce" --get-volume)
    angle=$((vol / 5 * 5))  # Fix the period problem, rounding the volume
    bar=$(printf '%.0s.' $(seq 1 $(($vol / 15))))
    output_device=$(get_active_output)
    device_name=$(get_friendly_device_name)  # Get the friendly output device name
    # Send notification with device name and volume level separately
    notify "Volume" "Device: $device_name\nLevel: ${vol}%" ""
}

notify_mute() {
    mute=$(pamixer "$srce" --get-mute)
    active_device=$([ "$srce" = "--default-source" ] && get_active_input || get_active_output)
    device_name=$(get_friendly_device_name)  # Get the friendly device name for mute/unmute notifications
    if [ "$mute" = "true" ]; then
        notify "Muted" "Device: $device_name\nMuted" ""
    else
        notify_vol
    fi
}

change_volume() {
    local action=$1 step=$2 device=$3 delta="-" mode="--output-volume"

    [ "$action" = "i" ] && delta="+"
    [ "$srce" = "--default-source" ] && mode="--input-volume"
    case $device in
        "pamixer")
            $use_swayosd && swayosd-client ${mode} "${delta}${step}" && exit 0
            pamixer $srce -"$action" "$step"
            ;;
        "playerctl")
            playerctl --player="$srce" volume "$(awk -v step="$step" 'BEGIN {print step/100}')${delta}"
            ;;
    esac
    notify_vol
}

toggle_mute() {
    local device=$1 mode="--output-volume"
    [ "$srce" = "--default-source" ] && mode="--input-volume"
    case $device in
        "pamixer")
            # Toggle mute and update the state accordingly
            $use_swayosd && swayosd-client "${mode}" mute-toggle && exit 0
            pamixer $srce -t
            ;;
        "playerctl")
            local volume_file="/tmp/$(basename "$0")_last_volume_${srce:-all}"
            current_vol=$(playerctl --player="$srce" volume | awk '{ printf "%.2f", $0 }')
            if [ "$current_vol" != "0.00" ]; then
                echo "$current_vol" > "$volume_file"
                playerctl --player="$srce" volume 0
            else
                playerctl --player="$srce" volume "$(cat "$volume_file" 2>/dev/null || echo 0.1)"
            fi
            ;;
    esac
    notify_mute
}

select_output() {
    local selection=$1
    if [ -n "$selection" ]; then
        device=$(pactl list sinks | grep -C2 -F "Description: $selection" | grep Name | cut -d: -f2 | xargs)
        if pactl set-default-sink "$device"; then
            notify "Activated" "$selection" ""
        else
            notify "Error" "Error activating $selection" ""
        fi
    else
        pactl list sinks | grep -ie "Description:" | awk -F ': ' '{print $2}' | sort
    fi
}

toggle_output() {
    local sink_array default_sink next_sink
    default_sink=$(get_active_output)
    mapfile -t sink_array < <(select_output)
    for i in "${!sink_array[@]}"; do
        if [[ "${sink_array[i]}" == "$default_sink" ]]; then
            next_sink="${sink_array[(i+1) % ${#sink_array[@]}]}"
            break
        fi
    done
    select_output "$next_sink"
}

# Print usage information when invalid arguments are given
print_usage() {
    echo "Usage: $0 [ -i | -o | -p <player> | -s | -t ] <action> [<step>]"
    echo "  -i            : Control input volume (microphone)"
    echo "  -o            : Control output volume (speakers)"
    echo "  -p <player>   : Control volume for a specific player (e.g., 'vlc', 'mpv')"
    echo "  -s            : Select audio output device"
    echo "  -t            : Toggle between available output devices"
    echo "  <action>      : i/d for increase/decrease volume"
    echo "  <step>        : Volume step for i/d (default is 1)"
    exit 1
}

# Main script logic

# Set default variables
icodir="${confDir}/dunst/icons/vol"
step=1

# Parse options
while getopts "iop:st" opt; do
    case $opt in
        i) device="pamixer"; srce="--default-source"; nsink=$(get_active_input) ;;
        o) device="pamixer"; srce=""; nsink=$(get_active_output) ;;
        p) device="playerctl"; srce="$OPTARG"; nsink=$(playerctl --list-all | grep -w "$srce") ;;
        s) select_output "$(select_output | rofi -dmenu -config "${confDir}/rofi/notification.rasi")"; exit ;;
        t) toggle_output; exit ;;
        *) print_usage ;;
    esac
done

shift $((OPTIND-1))

# Check if device is set
[ -z "$device" ] && print_usage

# Execute action
case $1 in
    i|d) change_volume "$1" "${2:-$step}" "$device" ;;
    m) toggle_mute "$device" ;;
    *) print_usage ;;
esac
