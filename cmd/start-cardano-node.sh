#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

# Running in loop allows for restarting without restarting the container
    while true; do
        echo "Starting cardano-node"
        echo "NODE_PATH=$NODE_PATH"
        cardano-node run \
            --topology ${NODE_PATH}/mainnet-topology.json \
            --database-path ${NODE_PATH}/db \
            --socket-path ${NODE_SOCKET_PATH} \
            --host-addr ${NODE_IP} \
            --port ${NODE_PORT} \
            --config ${NODE_PATH}/mainnet-config.json
    done

