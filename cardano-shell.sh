#!/usr/bin/env bash

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

if [ "$1" == "block" ]
then
    docker run \
    --name block-producer \
    --network=host \
    --restart unless-stopped \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it kunkka7/cardano-shell:latest -c 'source /cmd/config.sh; /cmd/start-node-with-shell.sh block'
elif [  "$1" == "relay" ]
then
    docker run \
    --name relay \
    --network=host \
    --restart unless-stopped \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it kunkka7/cardano-shell:latest -c 'source /cmd/config.sh; /cmd/start-node-with-shell.sh relay'
elif [  "$1" == "node" ]
then
    docker run \
    --name cardano-node \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it kunkka7/cardano-shell:latest -c 'source /cmd/config.sh; /cmd/start-node-with-shell.sh'
elif [  "$1" == "prometheus" ]
then
    docker run \
    --name prometheus \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it kunkka7/cardano-shell:latest -c 'source /cmd/config.sh; /cmd/start-prometheus-server.sh'
elif [  "$1" == "grafana" ]
then
    docker container rm grafana
    docker run \
    --name grafana \
    --network=host \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it kunkka7/cardano-shell:latest -c 'source /cmd/config.sh; /cmd/start-grafana-server.sh'
else
    docker run \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it kunkka7/cardano-shell:latest
fi

