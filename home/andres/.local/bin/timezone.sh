#!/bin/bash

# Define the time zones and corresponding city names
zones=("America/La_Paz" "Europe/Amsterdam" "Europe/Helsinki" "Asia/Tokyo")
names=("La Paz" "Amsterdam" "Helsinki" "Tokyo")

# Path to store the current index
index_file="/tmp/timezone_index"

# Function to get the current index
get_index() {
  if [[ -f "$index_file" ]]; then
    cat "$index_file"
  else
    echo 0
  fi
}

# Function to update the index
update_index() {
  local current_index=$(get_index)
  echo $(( (current_index + 1) % ${#zones[@]} )) > "$index_file"
}

# Function to get the current date, time, and city
get_time_and_date() {
  local current_index=$(get_index)
  local zone="${zones[$current_index]}"
  local city="${names[$current_index]}"

  # Get the formatted time and date
  local time=$(TZ="$zone" date "+%-I:%M %p")  # %-I removes leading zero from hour
  local date=$(TZ="$zone" date "+%A, %B %-d")  # %-d removes leading zero from day

  # Style the output using Pango markup
  echo "<span color='#8C70FA'><b>$city</b></span> $date - $time"
}

# Debugging: Log output to a file, but still return it to Waybar
log_debug() {
  local message="$1"
  echo "$message" >> /tmp/timezone_debug.log
}

# Handle "next" argument for cycling
if [[ "$1" == "next" ]]; then
  log_debug "Cycling to the next timezone"
  update_index
fi

# Get and display the current time and date
output=$(get_time_and_date)
log_debug "Output: $output"
echo "$output"
