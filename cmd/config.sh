#!/usr/bin/env bash

# cardano-node simple configuration
export NODE_PATH="/config"
export NODE_SOCKET_PATH="$NODE_PATH/node.socket"
export NODE_IP="127.0.0.1"
export NODE_PORT="3000"

# cardano-node relay configuration
export RELAY_IP="relay.stakepool.fr"
export RELAY_PORT="3000"

# cardano-node block-producer configuration
export BLOCK_IP="block.stakepool.fr"
export BLOCK_PORT="3000"

# required for cardano-node to function correctly
export CARDANO_NODE_SOCKET_PATH=$NODE_SOCKET_PATH
