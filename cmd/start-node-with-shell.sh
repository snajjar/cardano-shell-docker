#!/usr/bin/env bash

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

SESSION="CARDANO"

# Kill session from previous run (if exists)
tmux kill-session -t $SESSION

# Create a 3-panel session with 1) bash, 2) top and 3) cardano-node running
# forward arguments to /cmd/start-cardano-node.sh
tmux new-session -s "$SESSION" "/bin/bash" \; \
    split-window -d -h "/cmd/start-cardano-node.sh $1 $2" \; \
    split-window -t $SESSION:0.1 -d -v "/bin/bash" \; \
    send-keys -t $SESSION:0.2 "sleep 3; /cmd/start-monitoring.sh $1; grc tail -f /logs/node.log" Enter \;


