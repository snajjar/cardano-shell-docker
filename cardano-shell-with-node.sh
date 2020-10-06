#!/bin/sh

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

docker run \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -it cardano-stakepool:latest -c 'source /cmd/config.sh; /cmd/start-node-with-shell.sh'
