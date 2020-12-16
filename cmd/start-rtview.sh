#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

cd /RTView


if [ -f "/config/monitoring/RTView.json" ]; then
    pm2 start cardano-rt-view -l /logs/rtview-std.log -- --port $RTVIEW_PORT --config /config/monitoring/RTView.json --static /RTView/static
else
    echo "No /config/monitoring/RTView.json file, not starting RTView server"
fi