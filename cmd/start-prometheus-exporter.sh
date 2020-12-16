#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

if [ -f "/config/monitoring/prometheus/prometheus.yml" ]; then
    pm2 start prometheus-node-exporter --log /logs/prometheus-node-exporter.log -- --web.listen-address="0.0.0.0:$PROMETHEUS_NODE_PORT"
else
    echo "No $PROMETHEUS_DIR/prometheus.yml file, not starting prometheus exporter"
fi