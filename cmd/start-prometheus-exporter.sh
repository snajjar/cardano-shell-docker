#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

touch /logs/prometheus-node-exporter.log
pm2 start prometheus-node-exporter --log /logs/prometheus-node-exporter.log -- --web.listen-address="0.0.0.0:$PROMETHEUS_NODE_PORT"