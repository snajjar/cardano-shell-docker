#!/bin/sh

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

docker run \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/config/:/config/ \
    -v $ABS_CURR_DIR/scripts/:/scripts/ \
    -v $ABS_CURR_DIR/ressources/.bashrc:/.bashrc \
    -it cardano-stakepool
