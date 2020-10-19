#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

touch /logs/prometheus-node-exporter.log
prometheus-node-exporter --web.listen-address="0.0.0.0:$PROMETHEUS_NODE_PORT" > /logs/prometheus-node-exporter.log 2>&1 &