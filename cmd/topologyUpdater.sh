#!/bin/bash

# get all configuration env var
source /cmd/config.sh

# fetch topology update from adapools, add our block-producing server to it and IOHK's relay node
curl -s -o /config/topologyUpdateAdaPools.json https://a.adapools.org/topology?limit=20

# check for safety that we indeed have some relays
NUMBER_OF_RELAYS=$(echo $(jq ".Producers | length" /config/topologyUpdateAdaPools.json))
if [ "$NUMBER_OF_RELAYS" -gt "2" ]; then
    echo $(jq ".Producers[1] |= . + {\"type\": \"regular\", \"addr\": \"relays-new.cardano-mainnet.iohk.io\", \"port\": \"3001\"|tonumber, \"valency\": \"1\"|tonumber}" /config/topologyUpdateAdaPools.json) > /config/topologyUpdateAdaPools.json
    echo $(jq ".Producers[0] |= . + {\"type\": \"regular\", \"addr\": \"$BLOCK_IP\", \"port\": \"$BLOCK_PORT\"|tonumber, \"valency\": \"2\"|tonumber}" /config/topologyUpdateAdaPools.json) > /config/topologyUpdateAdaPools.json
    echo $(jq . /config/topologyUpdateAdaPools.json) > /config/topologyUpdateAdaPools.json
    mv /config/topologyUpdateAdaPools.json /config/mainnet-topology.json

    # kill the cardano-node (it will restart automatically)
    killall cardano-node

    echo "topology updated successfully, including $BLOCK_IP:$BLOCK_PORT"
else
    echo "topology update failed: found less than 2 relays"
fi