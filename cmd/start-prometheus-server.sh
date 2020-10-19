#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

export PROMETHEUS_DIR=/config/monitoring/prometheus/

mkdir -p $PROMETHEUS_DIR/data
sleep 3

pm2 start prometheus --log /logs/prometheus.logs -- --config.file=$PROMETHEUS_DIR/prometheus.yml --storage.tsdb.path=$PROMETHEUS_DIR/data