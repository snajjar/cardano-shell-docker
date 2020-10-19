#!/usr/bin/env bash

# get all configuration env var
source /cmd/config.sh

export GF_PATHS_CONFIG="/config/monitoring/grafana/grafana.ini"
export GF_PATHS_DATA="/config/monitoring/grafana/data"
export GF_PATHS_HOME="/usr/share/grafana"
export GF_PATHS_LOGS="/logs/grafana"
export GF_PATHS_PLUGINS="/var/lib/grafana/plugins"
export GF_PATHS_PROVISIONING="/etc/grafana/provisioning"
export GF_HOMEPATH="/config/monitoring/grafana"

export GF_SECURITY_ADMIN_USER="$GRAFANA_ADMIN_USER"
export GF_SECURITY_ADMIN_PASSWORD="$GRAFANA_ADMIN_PASSWORD"

mkdir -p $GF_PATHS_LOGS

# grafana-server --config /config/monitoring/grafana.ini --homepath /config/monitoring/grafana cfg:default.paths.logs=/logs/

echo "grafana-server --config $GF_HOMEPATH/grafana.ini --homepath $GF_HOMEPATH cfg:default.paths.logs=$GF_PATHS_LOGS"
grafana-server --config $GF_HOMEPATH/grafana.ini --homepath $GF_PATHS_HOME cfg:default.paths.logs=$GF_PATHS_LOGS