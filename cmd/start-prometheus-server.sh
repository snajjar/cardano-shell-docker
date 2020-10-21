#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

export PROMETHEUS_DIR=/config/monitoring/prometheus/

mkdir -p $PROMETHEUS_DIR/data
sleep 3

if [ -f "/config/monitoring/prometheus/prometheus.yml" ]; then
    pm2 start prometheus --log /logs/prometheus.logs -- --config.file=$PROMETHEUS_DIR/prometheus.yml --storage.tsdb.path=$PROMETHEUS_DIR/data --web.listen-address="0.0.0.0:$PROMETHEUS_WEB_PORT"
else
    echo "No $PROMETHEUS_DIR/prometheus.yml file, not starting prometheus server"
fi
