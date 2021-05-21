#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

# if the autotopology argument is used, add a crontask
if [ "$2" == "autotopology" ]; then
    echo "Starting cardano-node WITH auto-updating topology"
    # add a new crontab
    crontab -l > /config/topologycron
    #echo new cron into cron file
    echo "0 1 * * * /cmd/topologyUpdater.sh" >> /config/topologycron
    #install new cron file
    crontab /config/topologycron
    rm /config/topologycron

    /cmd/topologyUpdater.sh
else
    echo "Starting cardano-node WITHOUT auto-updating topology"
fi

if [ "$1" == "block" ]
then
    while true; do
        echo "Starting block-producing node"
        cardano-node run \
            --topology ${NODE_PATH}/mainnet-topology.json \
            --database-path ${NODE_PATH}/db \
            --socket-path ${NODE_SOCKET_PATH} \
            --host-addr $(dig +short $BLOCK_IP) \
            --port $BLOCK_PORT \
            --config ${NODE_PATH}/mainnet-config.json \
            --shelley-kes-key /config/keys/kes.skey \
            --shelley-vrf-key /config/keys/vrf.skey \
            --shelley-operational-certificate /config/keys/node.cert
    done
elif [  "$1" == "relay" ]
then
    while true; do
        echo "Starting relay node"
        cardano-node run \
            --topology ${NODE_PATH}/mainnet-topology.json \
            --database-path ${NODE_PATH}/db \
            --socket-path ${NODE_SOCKET_PATH} \
            --host-addr $(dig +short $RELAY_IP) \
            --port $RELAY_PORT \
            --config ${NODE_PATH}/mainnet-config.json
    done
else
    # Running in loop allows for restarting without restarting the container
    while true; do


        echo "Starting cardano-node"
        cardano-node run \
            --topology ${NODE_PATH}/mainnet-topology.json \
            --database-path ${NODE_PATH}/db \
            --socket-path ${NODE_SOCKET_PATH} \
            --host-addr $NODE_IP \
            --port ${NODE_PORT} \
            --config ${NODE_PATH}/mainnet-config.json
    done
fi



