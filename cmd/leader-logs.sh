#!/usr/bin/env bash

epoch="\${1:-next}"
timezone="\${2:-UTC}"

echo "socket: $CARDANO_NODE_SOCKET_PATH"
cardano-cli query ledger-state --mainnet > ${NODE_PATH}/db/ledger-state.json

function getStatus() {
    local result
    result=$(cncli status \
        --db ${NODE_PATH}/db/cncli.db \
        --byron-genesis ${NODE_PATH}/mainnet-byron-genesis.json \
        --shelley-genesis ${NODE_PATH}/mainnet-shelley-genesis.json \
        | jq -r .status
    )
    echo "\$result"
}

function getLeader() {
    cncli leaderlog \
        --db ${NODE_PATH}/db/cncli.db \
        --pool-id  $(cat ${NODE_PATH}/keys/poolid) \
        --pool-vrf-skey ${NODE_PATH}/keys/vrf.skey \
        --byron-genesis ${NODE_PATH}/mainnet-byron-genesis.json \
        --shelley-genesis ${NODE_PATH}/mainnet-shelley-genesis.json \
        --ledger-state ${NODE_PATH}/db/ledger-stage.json \
        --ledger-set "\$epoch" \
        --tz "\$timezone"
}

statusRet=$(getStatus)

if [[ "$statusRet" == "ok" ]]; then
    mv ${NODE_PATH}/logs/leaderlog.json ${NODE_PATH}/logs/leaderlog."\$(date +%F-%H%M%S)".json
    getLeader > ${NODE_PATH}/logs/leaderlog.json
    find . -name "leaderlog.*.json" -mtime +15 -exec rm -f '{}' \;
else
    echo "CNCLI database not synced!!!"
fi

exit 0