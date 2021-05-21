#!/bin/bash

# get all configuration env var
source /cmd/config.sh

# check our base topology file in base-topology.json
BASE_RELAYS=$(echo $(jq ".Producers | length" /config/base-topology.json))

# fetch topology update from adapools
curl -s -o /config/topologyUpdateAdaPools.json https://a.adapools.org/topology?limit=20

# check for safety that we indeed have some relays
NUMBER_OF_RELAYS=$(echo $(jq ".Producers | length" /config/topologyUpdateAdaPools.json))
if [ "$NUMBER_OF_RELAYS" -gt "2" ]; then
    # add our base relays
    jq -s ".[0].Producers=([.[].Producers]|flatten)|.[0]" /config/base-topology.json /config/topologyUpdateAdaPools.json > /config/mainnet-topology.json
    rm /config/topologyUpdateAdaPools.json

    # kill the cardano-node (it will restart automatically)
    killall cardano-node

    echo "topology updated successfully with $(jq ".Producers | length" /config/mainnet-topology.json) relays"
else
    echo "topology update failed: found less than 2 relays"
fi