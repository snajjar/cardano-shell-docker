#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

if [ "$1" == "block" ]
then
    # block: start prometheus exporter and server
    /cmd/start-prometheus-exporter.sh;
    /cmd/start-prometheus-server.sh;
elif [  "$1" == "relay" ]
then
    # relay: start prometheus exporter, server and RTView
    /cmd/start-prometheus-exporter.sh;
    /cmd/start-prometheus-server.sh;
    /cmd/start-rtview.sh
else
    # local node: start all
    /cmd/start-prometheus-exporter.sh;
    /cmd/start-prometheus-server.sh;
    /cmd/start-rtview.sh
fi

