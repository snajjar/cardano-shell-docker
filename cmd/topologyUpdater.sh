#!/bin/bash

# get all configuration env var
source /cmd/config.sh

# fetch topology update from adapools, add our block-producing server to it and IOHK's relay node
curl -s -o /config/topologyUpdateAdaPools.json https://a.adapools.org/topology?limit=20
echo $(jq ".Producers[1] |= . + {\"type\": \"regular\", \"addr\": \"relays-new.cardano-mainnet.iohk.io\", \"port\": \"3001\", \"valency\": \"1\"}" /config/topologyUpdateAdaPools.json) > /config/topologyUpdateAdaPools.json
echo $(jq ".Producers[0] |= . + {\"type\": \"regular\", \"addr\": \"$BLOCK_IP\", \"port\": \"$BLOCK_PORT\", \"valency\": \"2\"}" /config/topologyUpdateAdaPools.json) > /config/topologyUpdateAdaPools.json
echo $(jq . /config/topologyUpdateAdaPools.json) > /config/topologyUpdateAdaPools.json
mv /config/topologyUpdateAdaPools.json /config/mainnet-topology.sh

# kill the cardano-node (it will restart automatically)
killall cardano-node

echo "topology updated successfully, including $BLOCK_IP:$BLOCK_PORT"