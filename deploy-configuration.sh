#!/usr/bin/env bash

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

# Get configuration files
echo "[*] copying configuration files to docker"
sudo mkdir -p $ABS_CURR_DIR/docker/cmd

sudo cp $ABS_CURR_DIR/config/config.sh $ABS_CURR_DIR/docker/cmd/

if [ "$1" == "block" ]; then
    echo "[*] deploying configuration for block-producing node"
    sudo cp -r $ABS_CURR_DIR/config/block/* $ABS_CURR_DIR/docker/config
elif [  "$1" == "relay" ]; then
    echo "[*] deploying configuration for relay node"
    sudo cp -r $ABS_CURR_DIR/config/relay/* $ABS_CURR_DIR/docker/config
else
    echo "[*] deploying configuration for local node"
    sudo cp -r $ABS_CURR_DIR/config/node/* $ABS_CURR_DIR/docker/config
fi

sudo cp -r $ABS_CURR_DIR/ressources $ABS_CURR_DIR/docker/

echo "[*] copying RTView configuration to docker"
mkdir -p $ABS_CURR_DIR/docker/config/monitoring/

echo "[*] copying run scripts to docker"
sudo cp -r $ABS_CURR_DIR/cmd $ABS_CURR_DIR/docker/
sudo chmod +x $ABS_CURR_DIR/docker/cmd/*

echo "[*] copying adresses and public keys to docker"
sudo mkdir -p $ABS_CURR_DIR/docker/config/keys
sudo cp -r $ABS_CURR_DIR/.backup/secret/keys/stake.addr $ABS_CURR_DIR/docker/config/keys
sudo cp -r $ABS_CURR_DIR/.backup/secret/keys/payment.addr $ABS_CURR_DIR/docker/config/keys

