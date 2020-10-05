#!/bin/sh

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

SESSION="CARDANO"

# Get configuration files
echo "[*] fetching MAINNET configuration files..."
mkdir -p ressources/config/
cd ressources/config/
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-config.json
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-byron-genesis.json
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-shelley-genesis.json
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-topology.json

echo "[*] copying configuration files to docker config folder"
sudo cp *.json ../../config/
cd ../../

# Kill session from previous run (if exists)
tmux kill-session -t $SESSION

# Create a 3-panel session with 1) bash, 2) top and 3) cardano-node running
tmux new-session -s "$SESSION" "/bin/bash" \; \
    split-window -d -h "top" \; \
    split-window -t $SESSION:0.1 -d -v "/bin/bash" \;

#docker run \
#    --network=host \
#    --rm \
#    -v $ABS_CURR_DIR/config/:/config/ \
#    -v $ABS_CURR_DIR/scripts/:/scripts/ \
#    -v $ABS_CURR_DIR/ressources/.bashrc:/.bashrc \
#    -it cardano-stakepool
