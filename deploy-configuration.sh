#!/usr/bin/env bash

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

# Get configuration files
echo "[*] copying configuration files to docker"
sudo mkdir -p $ABS_CURR_DIR/docker

if [ $1 == "block" ]
then
    echo "Deploying configuration for block-producing node"
    sudo cp -r $ABS_CURR_DIR/config/block $ABS_CURR_DIR/docker/config
elif [  $1 == "relay" ]
then
    echo "Deploying configuration for relay node"
    sudo cp -r $ABS_CURR_DIR/config/relay $ABS_CURR_DIR/docker/config
else
    echo "Deploying configuration for local node"
    sudo cp -r $ABS_CURR_DIR/config/node $ABS_CURR_DIR/docker/config
fi

sudo cp -r $ABS_CURR_DIR/ressources $ABS_CURR_DIR/docker/

echo "[*] copying run scripts to docker"
sudo cp -r $ABS_CURR_DIR/cmd $ABS_CURR_DIR/docker/
sudo chmod +x $ABS_CURR_DIR/docker/cmd/*

echo "[*] copying adresses and public keys to docker"
sudo mkdir -p $ABS_CURR_DIR/docker/config/keys
sudo cp -r $ABS_CURR_DIR/.backup/keys/stake.addr $ABS_CURR_DIR/docker/config/keys
sudo cp -r $ABS_CURR_DIR/.backup/keys/payment.addr $ABS_CURR_DIR/docker/config/keys

