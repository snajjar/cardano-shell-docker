#!/usr/bin/env bash

# cardano-node simple configuration
export NODE_PATH="/config"
export NODE_SOCKET_PATH="$NODE_PATH/node.socket"
export NODE_IP="127.0.0.1"
export NODE_PORT="3000"

# required for cardano-node to function correctly
export CARDANO_NODE_SOCKET_PATH=$NODE_SOCKET_PATH

echo "NODE_PATH=$NODE_PATH"
echo "NODE_SOCKET_PATH=$NODE_SOCKET_PATH"
echo "NODE_IP=$NODE_PATH"
echo "NODE_PORT=$NODE_PATH"
