#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

export PROMETHEUS_DIR=/config/monitoring/prometheus/

mkdir -p $PROMETHEUS_DIR/data
prometheus --config.file=$PROMETHEUS_DIR/prometheus.yml --storage.tsdb.path=$PROMETHEUS_DIR/data