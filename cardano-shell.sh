#!/usr/bin/env bash

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

if [ $1 == "block" ]
then
    docker run \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -it cardano-stakepool:latest -c 'source /cmd/config.sh; /cmd/start-node-with-shell.sh block'
elif [  $1 == "relay" ]
then
    docker run \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -it cardano-stakepool:latest -c 'source /cmd/config.sh; /cmd/start-node-with-shell.sh relay'
elif [  $1 == "node" ]
then
    docker run \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -it cardano-stakepool:latest -c 'source /cmd/config.sh; /cmd/start-node-with-shell.sh'
else
    docker run \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -it cardano-stakepool:latest
fi

