#!/usr/bin/env bash

IMAGE="kunkka7/cardano-shell"
VERSION="latest"

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

# if node, block or relay, forward arguments to /cmd/start-node-with-shell.sh
if [ "$1" == "block" ]
then
    docker container rm block-producer 2> /dev/null
    docker run \
    --name block-producer \
    --network=host \
    --restart unless-stopped \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it $IMAGE:$VERSION -c "source /cmd/config.sh; /cmd/start-node-with-shell.sh $1 $2"
elif [  "$1" == "relay" ]
then
    docker container rm relay 2> /dev/null
    docker run \
    --name relay \
    --network=host \
    --restart unless-stopped \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it $IMAGE:$VERSION -c "source /cmd/config.sh; /cmd/start-node-with-shell.sh $1 $2"
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
    -it $IMAGE:$VERSION -c "source /cmd/config.sh; /cmd/start-node-with-shell.sh $1 $2"
elif [  "$1" == "prometheus" ]
then
    docker container rm prometheus 2> /dev/null
    docker run \
    --name prometheus \
    --network=host \
    --restart unless-stopped \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it $IMAGE:$VERSION -c 'source /cmd/config.sh; /cmd/start-prometheus-server.sh'
elif [  "$1" == "grafana" ]
then
    docker container rm grafana 2> /dev/null
    docker run \
    --name grafana \
    --restart unless-stopped \
    --network=host \
    -v $ABS_CURR_DIR/docker/logs/:/log/ \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it $IMAGE:$VERSION -c 'source /cmd/config.sh; /cmd/start-grafana-server.sh'
else
    docker run \
    --network=host \
    --rm \
    -v $ABS_CURR_DIR/docker/config/:/config/ \
    -v $ABS_CURR_DIR/docker/cmd/:/cmd/ \
    -v $ABS_CURR_DIR/docker/ressources/.bashrc:/root/.bashrc \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -it $IMAGE:$VERSION
fi

