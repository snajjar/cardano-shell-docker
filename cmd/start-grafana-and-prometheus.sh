#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

export SESSION="grafana"
tmux kill-session -t $SESSION

# Create a 3-panel session with 1) shell 2) prometheus, 2) grafana
tmux new-session -s "$SESSION" "/bin/bash" \; \
    split-window -d -h "/cmd/start-prometheus-server.sh" \; \
    split-window -t $SESSION:0.1 -d -v "/cmd/start-grafana-server.sh" \;