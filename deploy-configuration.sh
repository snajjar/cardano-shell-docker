#!/bin/sh

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

# Get configuration files
echo "[*] copying configuration files to docker volume folder"
sudo rm -rf $ABS_CURR_DIR/docker
sudo mkdir -p $ABS_CURR_DIR/docker
sudo cp -r $ABS_CURR_DIR/config/node $ABS_CURR_DIR/docker/config
sudo cp -r $ABS_CURR_DIR/ressources $ABS_CURR_DIR/docker/
sudo cp -r $ABS_CURR_DIR/cmd $ABS_CURR_DIR/docker/
sudo chmod +x $ABS_CURR_DIR/docker/cmd/*
