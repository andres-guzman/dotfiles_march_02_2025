#!/bin/bash

# Check if the IPC socket file exists
if [ -f /tmp/mpv_ipc_socket ]; then
  # If the socket exists, send the file to the existing instance
  mpv --idle=once --input-file=/tmp/mpv_ipc_socket loadfile "$1" append
else
  # If the socket doesn't exist, start a new instance
  mpv --no-terminal --force-window --input-ipc-server=/tmp/mpv_ipc_socket "$1"
fi
