#!/bin/bash

# Define the directory to watch
WATCHED_DIR="$HOME/.mackup2"

# Function to send SIGHUP to the mackup2 process
send_sighup() {
    local pid
    # Find the process ID of mackup2
    pid=$(pgrep -f /usr/local/bin/mackup2)
    if [[ -n "$pid" ]]; then
        echo "Sending SIGHUP to mackup2 process with PID: $pid"
        kill -SIGHUP "$pid"
    else
        echo "mackup2 process not found, starting it..."
        /usr/local/bin/mackup2 &
    fi
}

echo "Starting mackup2 watchdog..."
send_sighup
# Use fswatch to monitor the directory for changes
fswatch -o "$WATCHED_DIR"/*.cfg | while read f; do
    send_sighup
done
