# Cardano-shell-docker: docker-based image to run a Cardano Stake Pool

Cardano-shell-docker is an collection of utilities to simplify access to cardano-node and cardano-cli from a docker environment. No need to install from source, with specific version of ghc, libsodium and other specific libraries and build tools that might hard to build on your system, or that could break your package manager dependencies.

`DISCLAIMER`: I share my own work for free without any kind of warranty. **Use these tools at your own risk**.

`SECURITY NOTE`: From a security perspective, **you should always read the source of the docker images and scripts that you use**, especially when handling financial assets.

`WARNING`: Currently under construction. This project (under construction) is using bash. Windows is not officially supported.

# Installation / setup of cardano-shell

Install [docker](https://docs.docker.com/get-docker/), clone this project, then run pull the docker image

    docker pull kunkka7/cardano-shell

or built it directly from the Dockerfile

    $ docker build . -t kunkka7/cardano-shell

On Linux/Mac, from the root of the project, make the utility scripts executables with:

    $ chmod +x *.sh

Then, create in the `config` folder a `config.sh` file:

    #!/usr/bin/env bash

    # cardano-node simple configuration for local use
    export NODE_PATH="/config"
    export NODE_SOCKET_PATH="$NODE_PATH/node.socket"
    export NODE_IP="127.0.0.1"
    export NODE_PORT="3000"

    # cardano-node relay configuration
    export RELAY_IP="<my-relay-ip>"
    export RELAY_PORT="<my-relay-port>"
    export RELAY_USE_TOPOLOGY_UPDATER=1

    # cardano-node block-producer configuration
    export BLOCK_IP="<my-core-node-ip>"
    export BLOCK_PORT="3000"

    # RTView port
    export RTVIEW_PORT="13004"

    # prometheus export
    export PROMETHEUS_WEB_PORT="9090"
    export PROMETHEUS_CARDANO_PORT="12789" # must be configured in mainnet-topology.json
    export PROMETHEUS_NODE_PORT="12790"

    # grafana config
    export GRAFANA_ADMIN_USER="admin"
    export GRAFANA_ADMIN_PASSWORD="cardano-is-great" # default password, change it later when configuring grafana

    # required for cardano-node to function correctly
    export CARDANO_NODE_SOCKET_PATH=$NODE_SOCKET_PATH

Adapt and adjust this config file, don't hesitate to change ports, but keep in mind that you'll have to adjust your firewall rules accordingly.
This config file will be sourced in every shell opened in the docker environment with cardano-shell.

# Deploying configuration

In this tutorial, you'll launch several cardano-shell on different machines, a `local` machine to create your private keys and test stuff, a `relay` machine which will be your stakepool relay, and a `block-producing` machine which will be your core node that add blocks to the cardano blockchain.

For each of theses machines, you will deploy different configurations from the `config` folder, `config/node`, `config/relay` and `config/block`.
It's recommanded to keep on your local machine all the different configurations, then copy the appropriate config to each node with `scp -r`.

Once in the config folder, you can easily deploy your files to the docker environment with the `./deploy-configuration.sh` script, that basically, move stuff to the `docker` folder at the right location.

Before using cardano-shell on your each node, and each time after changing a config file, you'll need to deploy your new config to the docker environment with:

    ./deploy-configuration <node|relay|block>

If used without arguments, it will deploy the `config/node` folder. Since the docker folder is/will be priviledged, this script use sudo. Read it before you use it.

# Launching a cardano-shell

## Running a simple cardano-cli

To launch a shell able to run cardano-cli:

    $ ./cardano-shell.sh

Note that commands requiring to query the blockchain for information won't work in that mode, but it's still useful for some commands (generating keys, addresses, etc).

## Running cardano-cli with a node

To be able to run all cardano-cli commands, you'll need a cardano-node running AND synchronized.

In the `config/node` folder, fetch the mainnet node config files from IOHK:

    wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-config.json
    wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-byron-genesis.json
    wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-shelley-genesis.json
    wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-topology.json


If it's your first time running the cardano-shell with a node, run the deployment script (that will export scripts and configuration to the docker folder):

    $ ./deploy-configuration.sh node

Anytime you wish to change the node configuration, modify the .json files in the `config/node` folder, then run `deploy-configuration.sh` again.

Once again, you can launch a container with a running node and an open shell with:

    $ ./cardano-shell.sh node

This will launch a [tmux](https://en.wikipedia.org/wiki/Tmux) session with 3 panes. A shell, a cardano-node and a log-grepper. If you don't know how to operate tmux and you need to, I suggest you take a look at the [tmux cheat sheet](https://tmuxcheatsheet.com/).

If you need to fully reset the node at some point, delete the docker folder, then deploy the configuration again.

# Building a stake pool with cardano-shell

For that matter, the recommanded configuration is 3 hosts:
- 1 online relay node, we'll call it `relay`.
- 1 online block-producing node, we'll call is `block`
- 1 *local* host to securely create keys, and sign transactions with it. We'll call it `local`.

**For best security**, the keys creations and transactions signing should be done on a completely offline host.

**For a reasonable security/usability tradeoff**, run theses commands on a secured, firewalled host (that could be your local machine), that you can safely assume that it was never compromised.

## Understanding keys and addresses files

Generation procedures for keys and addresses usually output 3 files:
- file.skey: private signing key, SHOULD NEVER BE ONLINE
- file.vkey: public verification key, used in many procedures. Keep it offline too for best security
- file.addr: address corresponding to the key pair generated. Could be public if needed.

You'll generate a payment keypair/address, to honor your stakepool pledge, and a stake keypair/address, that will receive the rewards for your participation in the cardano blockchain.

Recommandation: Backup theses 3 files to a seperate secure location, never put it online (at least unencrypted).

## Generating payment keys/address and stake keys/address (HOT)

This procedure is for shelley mainnet. For testnet, replace in following commands `--mainnet` with `--testnet-magic 42`.

From `local` do the following:

launch a cardano-shell:

    ./cardano-shell.sh

In the shell, create a folder to hold our keys:

    mkdir -p /config/keys

generate the payment key pair:

    cardano-cli address key-gen \
      --verification-key-file config/keys/payment.vkey \
      --signing-key-file config/keys/payment.skey

generate the stake key pair:

    cardano-cli stake-address key-gen \
      --verification-key-file stake.vkey \
      --signing-key-file stake.skey

build the payment address:

    cardano-cli address build \
      --payment-verification-key-file /config/keys/payment.vkey \
      --stake-verification-key-file /config/keys/stake.vkey \
      --out-file /config/keys/payment.addr \
      --mainnet

build the stake address:

    cardano-cli stake-address build \
      --stake-verification-key-file /config/keys/stake.vkey \
      --out-file /config/keys/stake.addr \
      --mainnet

verify that all the files were built correctly (`ll` is alias for `ls -al`):

    # ll /config/keys
    total 24
    drwxr-xr-x 2 root root 240 Oct 10 16:22 .
    drwxr-xr-x 4 root root 304 Oct 10 16:22 ..
    -rw-r--r-- 1 root root 103 Oct 10 16:19 payment.addr
    -rw-r--r-- 1 root root 180 Oct 10 16:11 payment.skey
    -rw-r--r-- 1 root root 190 Oct 10 16:11 payment.vkey
    -rw-r--r-- 1 root root  59 Oct 10 16:22 stake.addr
    -rw-r--r-- 1 root root 176 Oct 10 16:16 stake.skey
    -rw-r--r-- 1 root root 186 Oct 10 16:16 stake.vkey

From your local shell from cardano-shell folder, backup the keys from the container on a local folder with root-restricted read permissions, for later use. From now one, you'll need sudo.

    mkdir -p .backup/secret
    cp -r ./docker/config/keys .backup/secret
    sudo chown -R root .backup/secret
    sudo chmod -R 400 .backup/secret

Create a encrypted archive that you'll backup somewhere. Don't hesitate to [gpg encrypt](https://linuxconfig.org/how-to-encrypt-and-decrypt-individual-files-with-gpg) it if your gpg keys are already securely backed up. Here's a simple way to create an encrypted archive:

    sudo zip --encrypt .backup/stakepool.zip docker/config/keys/

Remember not to use --password (zip) or --passphrase (gpg) or similar options, as the password would be stored in plain text in the shell history and in system memory. If you absolutely have to, use `set -o history` to turn off history, and `set +o history` to turn it back on.

Finally, close the cardano-shell and verify that the container is stopped and deleted with `docker list containers` and `docker list containers -a`.
Once done, delete the config/keys folders:

    rm -rf ./docker/config/keys/

Whenever we need to use some keys, we'll copy them our backup folder to docker, use them, then delete the files again.

## Registering the stake address in the blockchain

We will need to register our stake address with a transaction, meaning we'll have to pay for the transaction fee. It'll require interacting with the blockchain, you'll need to have a **running** and **synchronized** node.

First, deploy the node configuration (if you haven't done it yet)

    ./deploy-configuration.sh

Then run a shell with node

    ./cardano-shell.sh node

Some commands might need the blockchain to be synchronized. The blockchain is several GB, so it may take a while to have the node synchronized. Note that it's stored into `docker/config/db` folder, so if you delete the `docker` folder, you will have to download it again.

First, we need to generate a registration certificate.
From a `local` shell, Copy the stake.vkey to the docker:

    sudo cp .backup/secret/keys/stake.vkey docker/config/keys/

Then from the **cardano-shell**, create the certificate:

    cardano-cli stake-address registration-certificate \
      --stake-verification-key-file /config/keys/stake.vkey \
      --out-file /config/keys/stake.cert

From the `local` shell, copy it to our backup folder:

    sudo cp docker/config/keys/stake.cert .backup/secret/keys/
    sudo chmod 400 .backup/secret/keys/stake.cert

Now, we need to know how much ada we need to send to our payment address. First, go on the cardano-shell a check what are the protocol amounts:

    # mkdir /work
    # cd /work
    # cardano-cli query protocol-parameters \
        --mainnet \
        --out-file protocol.json
    # grep keyDeposit protocol.json
        "keyDeposit": 2000000,

Here, we have to make a deposit of 2 million lovelaces, which is 2 ADA, in addition to the transaction fees.

Following the [cardano transaction tutorial](https://cardano-foundation.gitbook.io/stake-pool-course/stake-pool-guide/stake-key/register_key), we're going to draft our transaction and determine all the parameters.

First, query the current utx0 balance using the bashrc alias `sp-balance` or:

    # cardano-cli query utxo --address $(cat /config/keys/payment.addr) --mainnet
    TxHash                                                               TxIx      Lovelace
    98952480a220f83947fec475c2ff6c4327a18d2798a04fnuv1c49eab307224d8     0         100000000

From theses information, we get our UTX0 number, or TxIx and our current lovelace amount (ada amount * 1000000). In this example, we have `100 ada` so it's `100 millions lovelaces`.

First, draft our transaction with these parameters (leaving 0 for the info we don't have yet). Make sure to include the TxIx after the `#`. Save this command in a notepad as we will rework it later.

    cardano-cli transaction build-raw \
      --tx-in 98952480a220f83947fec475c2ff6c4327a18d2798a04fnuv1c49eab307224d8#0 \
      --tx-out $(cat /config/keys/payment.addr)+0 \
      --ttl 0 \
      --fee 0 \
      --out-file tx.raw \
      --certificate-file /config/keys/stake.cert

Then query the TTL using `sp-ttl` alias or:

    # cardano-cli query tip --mainnet
    {
        "blockNo": 4805198,
        "headerHash": "af0d79958d44342e53b53e2056dfb210c11f76213372fde61739e5e270c8c1d7",
        "slotNo": 10861266
    }

`slotNo` is the current slot number. Our transaction TTL will be a number chosen so that:
- We have time to finish submitting our transaction before `slotNo` reach our TTL
- Our transaction should be failed (and our funds available again) if it isn't executed when `slotNo` reach our TTL.

Usually, adding 10000 or 50000 to the current `slotNo` is a good option.

    # expr 10861266 + 50000
    10911266

Now that we have our TTL, let's calculate the last part: the fees (and the remaining amount on our account).

    # cardano-cli transaction calculate-min-fee \
      --tx-body-file tx.raw \
      --tx-in-count 1 \
      --tx-out-count 1 \
      --witness-count 1 \
      --byron-witness-count 0 \
      --mainnet \
      --protocol-params-file protocol.json
    172629 Lovelace


We've seen earlier that the keyDeposit will be 2000000 lovelaces, so we need to include that, to calculate our remaining amount of lovelace:

    expr 100000000 - 2000000 - 172629
    97827371

Now, we have all informations to draft our final transaction:

    cardano-cli transaction build-raw \
      --tx-in 98952480a220f83947fec475c2ff6c4327a18d2798a04fnuv1c49eab307224d8#0 \
      --tx-out $(cat /config/keys/payment.addr)+97827371 \
      --ttl 10911266 \
      --fee 172629 \
      --out-file tx.raw \
      --certificate-file /config/keys/stake.cert

Once run, you should have a tx.raw file in your current folder `/work`. Before submitting this transaction to the blockchain, we need to sign it with our private payment and stake signing keys.

On your `local` shell, transfer the keys to the docker container:

    sudo cp .backup/secret/keys/payment.skey docker/config/keys/
    sudo cp .backup/secret/keys/stake.skey docker/config/keys/

Then in the cardano shell, sign the transaction:

    cardano-cli transaction sign \
      --tx-body-file tx.raw \
      --signing-key-file /config/keys/payment.skey \
      --signing-key-file /config/keys/stake.skey \
      --mainnet \
      --out-file tx.signed

You should now have a `tx.signed` file in your local folder. Submit the transaction to the blockchain:

    cardano-cli transaction submit \
      --tx-file tx.signed \
      --mainnet

And voila! Now, we can query with `sp-balance` our balance to see if the fees and deposit have been paid, meaning the transaction has been successfully executed by the blockchain.

Note that if you meet [BadInputsUTxO](https://iohk.zendesk.com/hc/en-us/articles/900001210346-Transactions-errors-BadInputsUTxO-) or [ValueNotConservedUTxO](https://iohk.zendesk.com/hc/en-us/articles/900001220843-Transaction-errors-ValueNotConservedUTxO), it means that you made some mistakes with the parameters. Please check them out again.

When done, don't forget to delete the keys from your docker directory:

    sudo rm -rf docker/config/keys/*.skey
    sudo rm -rf docker/config/keys/*.vkey


## Generate our stake pool keys and certificate

On your `local` machine, perform the following procedure.

Start a shell with node:

    ./cardano-shell.sh node

Generate cold keys for your stakepool:

    cardano-cli node key-gen \
      --cold-verification-key-file /config/keys/cold.vkey \
      --cold-signing-key-file /config/keys/cold.skey \
      --operational-certificate-issue-counter-file /config/keys/cold.counter

Generate a VRF keypair:

    cardano-cli node key-gen-VRF \
    --verification-key-file /config/keys/vrf.vkey \
    --signing-key-file /config/keys/vrf.skey

Generate a [KES](https://cardano-foundation.gitbook.io/stake-pool-course/stake-pool-guide/stake-pool/kes_period) keypair:

    cardano-cli node key-gen-KES \
    --verification-key-file /config/keys/kes.vkey \
    --signing-key-file /config/keys/kes.skey

Now, we need to check what is the start of our KES validity period (check the above link to understand why).

get the current block number with `sp-ttl` command in the cardano-shell:

    # sp-ttl
    {
        "blockNo": 4805614,
        "headerHash": "5469dcf22575fb9a9dc1eba37fd15e94ff98272696c3d1af6baca5930e8623ae",
        "slotNo": 10869566
    }

We can check now in the `mainnet-shelley-genesis` file what is our KES period:

    $ grep KES mainnet-shelley-genesis.json
      "slotsPerKESPeriod": 129600,
       "maxKESEvolutions": 62,

In this example, each KES period is 129600 slots. So the current KES period started at 10869566 / 129600:

    $ expr 10869566 / 129600
    83

We can now create our node certificate:

    cardano-cli node issue-op-cert \
      --kes-verification-key-file kes.vkey \
      --cold-signing-key-file cold.skey \
      --operational-certificate-issue-counter cold.counter \
      --kes-period 83 \
      --out-file node.cert

From our local shell, move our files to the backup folder, rebuild our archive zip, and delete the keys from the docker folder:

    sudo cp -r ./docker/config/keys .backup/secret
    sudo chmod 400 /docker/config/keys/*
    sudo zip --encrypt .backup/secret/stakepool.zip .backup/secret/keys/
    sudo rm -rf ./docker/config/keys


Save your stakepool.zip archive to a cold secure location.

## Configure the relay and block-producer nodes


### Configure topology files for block-producing and relay nodes.

First, we need to edit our configuration files.

Copy configuration files ([fetched from IOHK](https://iohk.zendesk.com/hc/en-us/articles/900001951686-Starting-the-node-and-connecting-to-mainnet)) from `config/node` folder to `config/relay` and `config/block`.

Edit `config/block/mainnet-topology.json` to set change the addr/port settings to your **relay** node public ip/port

    {
        "Producers": [
            {
            "addr": "relay.stakepool.fr",
            "port": 3000,
            "valency": 2
            }
        ]
    }

Then edit `config/relay/mainnet-topology.json` to set your relay to communicate with your **block-producing** node ip/port, and with other relays of the network. You can find a list of mainnet relays on [adapools](https://a.adapools.org/topology)

    {
    "Producers": [
        {
        "addr": "block.stakepool.fr",
        "port": 3000,
        "valency": 1
        },
        {
        "addr": "relays-new.cardano-mainnet.iohk.io",
        "port": 3001,
        "valency": 2
        },
        {
            "type": "regular",
            "addr": "51.79.35.204",
            "port": 3001,
            "valency": 1
        },
        {
            "type": "regular",
            "addr": "usa-relay.cardanistas.io",
            "port": 8082,
            "valency": 1
        },
        ...
    }

Update the `cmd/config.sh` script as well with your relay and block ip/port.

On the `relay` host, clone this project, then build the docker image.
Once done, copy from the `local` machine your config files:

    scp -r ./config/ user@<relay ip>:path/to/repo

Then, deploy the relay configuration to the docker:

    ./deploy-configuration.sh relay

Then start your relay node

    ./cardano-shell.sh relay

And that's it, you relay should be working! Note that using the `relay` or `block` arguments, docker is launched with --restart unless-stopped, meaning it will reboot with your machine. You can stop it with `docker container list` and `docker stop <containerid>`.
If you want to detach from the docker session without closing anything, use `<ctrl+p> <ctrl+q>` to detach. You can reattach later with `docker container list` and `docker attach <containerid>`.

Now, time to start our block-producing node, also sometime called *core node*.

On the `block` node, pull the project and scp config files, just like for the relay node. Then, deploy the block-producer configuration:

    ./deploy-configuration.sh block

You need a few additional files to run the block-producing node: the pool keys `kes.skey`, `vrf.skey`, and `node.cert`. Copy them to your block host from `local`:

    mkdir poolkeys
    sudo cp .backup/secret/keys/kes.skey ./poolkeys
    sudo cp .backup/secret/keys/vrf.skey ./poolkeys
    sudo cp .backup/secret/keys/node.cert ./poolkeys
    sudo chown -R $(whoami) poolkeys
    scp -r poolkeys/ user@<relay ip>:path/to/repo
    rm -rf poolkeys/

Then from the `block host`

    sudo mkdir -p docker/config/keys/
    sudo mv poolkeys/* docker/config/keys/
    rm -r poolkeys

You can now run the block-producing node

    ./cardano-shell block

Once started, you can delete the pool keys again:

    rm -rf docker/config/keys/*.skey
    rm -rf docker/config/keys/node.cert


## Register the stakepool metadata

Create a .json file with your stakepool info

    {
        "name": "TestPool",
        "description": "The pool that tests all the pools",
        "ticker": "TEST",
        "homepage": "https://teststakepool.com"
    }

You are not required to have a live homepage (for now). Note that the `ticker` is the search string that will allow users to find your pool.

Upload it to an url that is less that 65 characters long (you can use `gist`  and `git.io` to shorten the url).

cp that file to the docker/config/ folder so we can access it from our cardano-shell

    sudo cp ./config/metadata.json docker/config/

Then from your local cardano-shell, get the hash:

    cardano-cli stake-pool metadata-hash --pool-metadata-file /config/metadata.json

Finally, we are able to create our stakepool registration certificate. Choose your:
- pool pledge (amount that you will stake. YOU MUST HONOR YOUR PLEDGE)
- pool cost (cost of running your pool)
- pool margin (% of rewards)

Once you decide those numbers (in lovelace), copy the necessary key files to your docker config

    sudo cp .backup/secret/keys/cold.vkey docker/config/keys/
    sudo cp .backup/secret/keys/vrf.vkey docker/config/keys/
    sudo cp .backup/secret/keys/stake.vkey docker/config/keys/

then create you docker certificate:

    cardano-cli stake-pool registration-certificate \
        --cold-verification-key-file /config/keys/cold.vkey \
        --vrf-verification-key-file /config/keys/vrf.vkey \
        --pool-pledge <pool pledge> \
        --pool-cost <pool cost> \
        --pool-margin <pool margin> \
        --pool-reward-account-verification-key-file /config/keys/stake.vkey \
        --pool-owner-stake-verification-key-file /config/keys/stake.vkey \
        --mainnet \
        --pool-relay-ipv4 <relay ip> \
        --pool-relay-port <relay port> \
        --metadata-url <metadata json url> \
        --metadata-hash <metadata hash> \
        --out-file /config/keys/pool-registration.cert

Create the delegation certificate (that will be used to honor our pledge)

    cardano-cli stake-address delegation-certificate \
        --stake-verification-key-file /config/keys/stake.vkey \
        --cold-verification-key-file /config/keys/cold.vkey \
        --out-file /config/keys/delegation.cert

Once done, backup this file in our backup folder (from our local shell):

    sudo cp docker/config/keys/pool-registration.cert .backup/secret/keys/
    sudo cp docker/config/keys/delegation.cert .backup/secret/keys/
    sudo chmod 400 .backup/secret/keys/pool-registration.cert
    sudo chmod 400 .backup/secret/keys/delegation.cert

Now, we need to submit our pool-registration.cert and delegation.cert to the blockchain.

Create a work directory for the transaction, get protocol.json and check what our pool deposit needs to be.

    # mkdir /work
    # cd /work
    # cardano-cli query protocol-parameters --mainnet --out-file protocol.json
    # grep poolDeposit protocol.json
    "poolDeposit": 500000000,

Our pool deposit will be 500 ada (~5$ when i'm writing this). We won't need to pay the deposit again if we need to update the pool certificate (changing pledge, margin, metadata, etc).

So, let's build the transaction (same procedure as for registring stake key).
We will need to use `stake.skey`, `payment.skey` and `cold.skey` to sign the transaction:

    sudo cp .backup/secret/keys/payment.skey docker/config/keys/
    sudo cp .backup/secret/keys/stake.skey docker/config/keys/
    sudo cp .backup/secret/keys/cold.skey docker/config/keys/

check your utxo with `sp-balance` and the current ttl with `sp-ttl`.

Here's our base command for building the transaction:

    cardano-cli transaction build-raw \
        --tx-in <utxo number>#<txix> \
        --tx-out $(cat /config/keys/payment.addr)+0 \
        --ttl 0 \
        --fee 0 \
        --out-file tx.raw \
        --certificate-file /config/keys/pool-registration.cert



For calculating the min fee, we will use a witness count of 3 (since we will sign with payment.skey, stake.skey and cold.skey).

    cardano-cli transaction calculate-min-fee \
        --tx-body-file tx.raw \
        --tx-in-count 1 \
        --tx-out-count 1 \
        --mainnet \
        --witness-count 3 \
        --byron-witness-count 0 \
        --protocol-params-file protocol.json


Then, using `expr <mybalance> - 500000000 - <minfees>`, we can deduct the remaining amount, and build the full request, which will look like this:

    cardano-cli transaction build-raw \
        --tx-in <utxo number>#<txix> \
        --tx-out $(cat /config/keys/payment.addr)+<remaining_amount> \
        --ttl <current slotNo + 50000> \
        --fee <minfee> \
        --out-file tx.raw \
        --certificate-file /config/keys/pool-registration.cert \
        --certificate-file /config/keys/delegation.cert

Once this is done, sign the transaction:

    cardano-cli transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file /config/keys/payment.skey \
        --signing-key-file /config/keys/stake.skey \
        --signing-key-file /config/keys/cold.skey \
        --mainnet \
        --out-file tx.signed

And finally, submit it to the blockchain:

    cardano-cli transaction submit \
        --tx-file tx.signed \
        --mainnet

Check with `sp-balance` if your amount was deducted from your payment address. If so, congratulation, your stakepool is not registered to the blockchain! You can check on adapools.org if you can see it.

You can also check on cardano-cli. Get your pool id with:

    cardano-cli stake-pool id --verification-key-file /config/keys/cold.vkey

Then:

    cardano-cli query ledger-state --mainnet | grep publicKey | grep <poolid>

should return a non-empty string.

Save your poolid into the backup directory:

    echo <poolid> > poolid
    sudo mv poolid .backup/secret/keys/

Now we can delete your keys from our node folder:

    sudo rm docker/config/keys/*.skey
    sudo rm docker/config/keys/*.vkey

Create a .zip encrypted backup for your config folder, and save it somewhere safe.

    sudo zip --encrypt .backup/secret/stakepool.zip docker/config/keys/

## Move the Stake Pool Pledge to a Cold Wallet (Ledger/Trezor)

If the stake becomes heavy, it's better to add additionnal security.

Instructions are from here: https://github.com/angelstakepool/add-hw-wallet-owner-to-pool

### Note: wait 2 epochs when you are done before transferring the funds

Important step. We need to move the pledge when the new owner is definitely registered, otherwise it wouldn't count as a pledge. If you moove the funds too soon, you will not meet your pledge at the end of the epochs (since the new address won't be counted) and nobody gets rewards.

### Step 1: create a wallet on Daedalus or Yoroi from your Ledger, put some ADAs on it.

Your hardware wallet will generate the keys from this operation.

### Step 2: use cardano-hw-cli to export public keys

Install:

    git clone https://github.com/vacuumlabs/cardano-hw-cli
    cd cardano-hw-cli
    yarn
    yarn build-tar

Then:

    sudo ./cardano-hw-cli address key-gen \
        --path 1852H/1815H/0H/2/0 \
        --verification-key-file hw-stake.vkey \
        --hw-signing-file hw-stake.hwsfile

Transfer theses new files to the `docker/config/keys/` folder with `./deploy-configuration.sh`

### Step 3: generate a new stake pool certificate, adding a new owner (the hardware wallet) to the stake pool

On the cardano-shell (with node), run

    cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file /config/keys/cold.vkey \
    --vrf-verification-key-file /config/keys/vrf.vkey \
    --pool-pledge <pool pledge> \
    --pool-cost <pool cost> \
    --pool-margin <pool margin> \
    --pool-reward-account-verification-key-file /config/keys/hw-stake.vkey \
    --pool-owner-stake-verification-key-file /config/keys/stake.vkey \
    --pool-owner-stake-verification-key-file /config/keys/hw-stake.vkey \
    --mainnet \
    --single-host-pool-relay relay.stakepool.fr \
    --pool-relay-port 3000 \
    --metadata-url <metadata.json> \
    --metadata-hash <metadata hash> \
    --out-file /config/keys/pool-registration.cert

### Step 3: create a transaction and use cardano-hw-cli to sign it

Now, we can create a new transaction to update our stake pool. We will sign it with 4 witnesses.
Like for updating the registring the stake pool, we need to use an appropriate TTL and fees.

Note: use the appropriate era specifier if required (currently it's --allegra-era)

Draft a first transaction (with 0 and 0 fees). With a ledger hardware wallet (as a security measure), you can only sign with 1 certificate, so we'll use the pool-registration.cert only in this example.

    cardano-cli transaction build-raw \
        --tx-in <txid>#0 \
        --tx-out $(cat /config/keys/payment.addr)+0 \
        --ttl <ttl> \
        --fee 0 \
        --out-file tx.raw \
        --certificate-file /config/keys/pool-registration.cert

Calculate fees with the following:

    cardano-cli query protocol-parameters \
            --mainnet \
            --out-file protocol.json
    cardano-cli transaction calculate-min-fee \
        --tx-body-file tx.raw \
        --tx-in-count 1 \
        --tx-out-count 1 \
        --mainnet \
        --witness-count 4 \
        --byron-witness-count 0 \
        --protocol-params-file protocol.json

Build your final transaction:

    cardano-cli transaction build-raw \
        --tx-in <txid>#0 \
        --tx-out $(cat /config/keys/payment.addr)+<remaining-balance> \
        --ttl <ttl> \
        --fee <fee> \
        --out-file tx.raw \
        --certificate-file /config/keys/pool-registration.cert

Now create 4 witness files:

    cardano-cli transaction witness \
    --tx-body-file tx.raw \
    --signing-key-file /config/keys/cold.skey \
    --mainnet \
    --out-file cold.witness

    cardano-cli transaction witness \
    --tx-body-file tx.raw \
    --signing-key-file /config/keys/stake.skey \
    --mainnet \
    --out-file stake.witness

    cardano-cli transaction witness \
    --tx-body-file tx.raw \
    --signing-key-file /config/keys/payment.skey \
    --mainnet \
    --out-file cli-payment.witness


This last witness can be done from a COLD machine. We'll use cardano-hw-cli instead of cardano-cli to sign this.
Sudo is probably needed to access to your hardware wallet, do not hesistate to use it.

Adapt the different file paths in the following command, then take the hw-stake.witness file with you back on the HOT machine that will submit the transaction.

    cp tx.raw /config/tx.raw
    sudo /path/to/cardano-hw-cli transaction witness \
    --tx-body-file ./docker/config/tx.raw \
    --hw-signing-file .backup/secret/keys/hw-stake.hwsfile \
    --mainnet \
    --out-file ./docker/config/keys/hw-stake.witness

Once you have gathered all the witnesses, assemble the transaction in 1 file, and submit it. All done.

    cardano-cli transaction assemble \
    --tx-body-file tx.raw \
    --witness-file cold.witness \
    --witness-file stake.witness \
    --witness-file cli-payment.witness \
    --witness-file /config/keys/hw-stake.witness \
    --out-file tx.multisign

    cardano-cli transaction submit \
        --tx-file tx.multisign \
        --mainnet


## Rotate your KES keypair

The KES keypair you generated is only valid for a certain number of epochs. After 3 month, your KES keypair will become "poisoned", you will have to generate another if you want to keep your node able to sign blocks.

From your `local` machine, launch a cardano-shell (with node), and generate a new KES keypair.

    cardano-cli node key-gen-KES \
        --verification-key-file /config/keys/kes.vkey \
        --signing-key-file /config/keys/kes.skey

Now, we'll issue a new opcert, confirming with cold.skey that this new kes key is our. We need the current KES period for that, which is the current slot number, divided by the number of slots per KES configured for this era. You can calculate it as such:

    # grep KES /config/mainnet-shelley-genesis.json
    "slotsPerKESPeriod": 129600,
    "maxKESEvolutions": 62,

    # sp-ttl
    {
        "blockNo": 5409128,
        "headerHash": "31927a0b48768a486256588567609286274a09d7aa5586c8e93b0dc3ddcb89f8",
        "slotNo": 23117420
    }

    # expr 23117420 / 129600
    178

Now we can issue or new node certificate:

    cardano-cli node issue-op-cert \
    --kes-verification-key-file /config/keys/kes.vkey \
    --cold-signing-key-file /config/keys/cold.skey \
    --operational-certificate-issue-counter /config/keys/cold.counter \
    --kes-period 178 \
    --out-file /config/keys/node.cert

Save your keys to your local `.backup` folder.

Copy `kes.vkey` and the new `node.cert` file to the `block` machine (in the docker/config/keys subfolder), and restart the block-producer docker with `docker container restart block-producer`.

## Update the stakepool parameters

Over time, you'll gather more funds. You might want to change your pledge, your margin, or some of your metadata.

Proceed like for the initial pool registration, but this time you don't have to pay deposit fees.


## Install Monitoring (RTView, Prometheus and Grafana)

Prometheus allows to fetch and graph application metrics, Grafana is
a very nice interface to display and organize all of them.

Best practice is to have a specific `monitoring` node. If you don't want to run one more serveur, use your `relay` node if you want to have your monitoring available from anywhere, as it does not host sensitive files and operations.
You can also use your `local` node, but if it's not available and connected 24/7, you wont be able to configure efficient alerts.

### Setting up RTView

Since the LiveView mode has been deleted, we need to set up RTView if we want to see live metrics on our nodes.

To set it up, create in each monitoring directory `config/node/monitoring`, `config/relay/monitoring` and `config/block/monitoring`) a file named `RTView.json`. Upon the presence of this file, a RTView server will be started when you start `./cardano-shell.sh [node|block|relay]`.

The HTTP server will be launched at the port specified with the `RTVIEW_PORT` environment variable from your `/config/config.sh` script.

Of course, you need to adapt this file to your local cardano-node port.

    {
        "rotation": null,
        "defaultBackends": ["KatipBK"],
        "setupBackends": ["KatipBK", "LogBufferBK", "TraceAcceptorBK"],
        "hasPrometheus": null,
        "hasGraylog": null,
        "hasGUI": null,
        "traceForwardTo": null,
        "traceAcceptAt": [{
            "remoteAddr": {
                "tag": "RemoteSocket",
                "contents": ["0.0.0.0", "3000"]
            },
            "nodeName": "block"
        }],
        "defaultScribes": [
            ["StdoutSK", "stdout"]
        ],
        "options": {
            "mapBackends": {
                "cardano-rt-view.acceptor": ["LogBufferBK", {
                    "kind": "UserDefinedBK",
                    "name": "ErrorBufferBK"
                }]
            }
        },
        "setupScribes": [{
            "scMaxSev": "Emergency",
            "scName": "/logs/rtview.log",
            "scRotation": null,
            "scMinSev": "Notice",
            "scKind": "FileSK",
            "scFormat": "ScText",
            "scPrivacy": "ScPublic"
        }],
        "hasEKG": null,
        "forwardDelay": null,
        "minSeverity": "Info"
    }

Now, we need to update our `config/[node|relay|block]/mainnet-config.json` files to forward our metrics to our RTView server.

First, Make sure you set `TurnOnLogMetrics` to `true`.

Second, Add the TraceForwarderBK Backend as such:

    "setupBackends": [
        "KatipBK",
        "TraceForwarderBK"
    ],

Third, configure your metrics to be handled by TraceForwarderBK. If you want all of them, use the following configuration:

    "options": {
        "mapBackends": {
            "cardano.node.resources": [
                "EKGViewBK",
                "TraceForwarderBK"
            ],
            "cardano.node-metrics": [
                "EKGViewBK",
                "TraceForwarderBK"
            ],
            "cardano.node.metrics": [
                "EKGViewBK",
                "TraceForwarderBK"
            ],
            "cardano.node.metrics.connectedPeers": [
                "EKGViewBK",
                "TraceForwarderBK"
            ],
            "cardano.node.metrics.ChainDB": [
                "EKGViewBK",
                "TraceForwarderBK"
            ],
            "cardano.node.metrics.Forge": [
                "EKGViewBK",
                "TraceForwarderBK"
            ],
            "cardano.node.metrics.peersFromNodeKernel": [
                "TraceForwarderBK"
            ],
            "cardano.node.AcceptPolicy": [
                "TraceForwarderBK"
            ],
            "cardano.node.ChainDB": [
                "TraceForwarderBK"
            ],
            "cardano.node.DnsResolver": [
                "TraceForwarderBK"
            ],
            "cardano.node.DnsSubscription": [
                "TraceForwarderBK"
            ],
            "cardano.node.ErrorPolicy": [
                "TraceForwarderBK"
            ],
            "cardano.node.Handshake": [
                "TraceForwarderBK"
            ],
            "cardano.node.IpSubscription": [
                "TraceForwarderBK"
            ],
            "cardano.node.LocalErrorPolicy": [
                "TraceForwarderBK"
            ],
            "cardano.node.LocalHandshake": [
                "TraceForwarderBK"
            ],
            "cardano.node.Mux": [
                "TraceForwarderBK"
            ]
        },
        ...
    }

Finally, forward the metrics to our server.

    "traceForwardTo": {
        "tag": "RemoteSocket",
        "contents": [
        "0.0.0.0",
        "3000"
        ]
    }

 In this example, each node forward metrics to it's local server. You can also decide to create 1 RTView server on your `relay` node (or better, in your `monitoring` node), and forward your metrics to it.

 You will just need to adapt the `traceAcceptAt` settings in the RTView.json file and the `traceForwardTo` settings in the mainnet-config.json files.

### Install Prometheus metrics

First, we want to allow our cardano-node to output prometheus metric. Edit `mainnet-config.json` in our `config/relay` and in our `config/block` folder. If you want to test the setup locally, you may also use edit the one in the `config/node` folder.

    "hasPrometheus": [
        "0.0.0.0",
        12789
    ],

Now, edit the `cmd/config.sh` file and set values for our PROMETHEUS and GRAFANA variables. I recommand choosing different ports than the default ones, but you will need to adapt the rest of the tutorial.

    # prometheus export
    export PROMETHEUS_WEB_PORT="9090"
    export PROMETHEUS_CARDANO_PORT="12789" # must be configured in mainnet-topology.json
    export PROMETHEUS_NODE_PORT="12790"

    # grafana config
    export GRAFANA_ADMIN_USER="myuser"
    export GRAFANA_ADMIN_PASSWORD="myadminpw" # change it later when configuring grafana

Finally, we need to create the `config/relay/monitoring/prometheus` and `config/block/monitoring/prometheus` folders and add a Prometheus configuration file in it (named `prometheus.yml`). Upon the presence of this file, cardano-shell will automatically start a prometheus-node-exporter (for system metrics) and a prometheus server on your node.

    global:
        scrape_interval:     15s
        external_labels:
            monitor: 'codelab-monitor'

    scrape_configs:
      - job_name: 'cardano' # To scrape data from the cardano node
          scrape_interval: 5s
          static_configs:
          - targets: ['127.0.0.1:12789']
      - job_name: 'node' # To scrape data from a node exporter to monitor your linux host metrics.
        scrape_interval: 5s
        static_configs:
        - targets: ['127.0.0.1:12790']

Once done, prometheus can be run. Don't forget to deploy your configuration again.
On relay node:

    ./deploy-configuration.sh relay
    ./cardano-shell.sh relay

On block node:

    ./deploy-configuration.sh block
    ./cardano-shell.sh block

You can verify that prometheus is running correctly by accessing the http://\<your-node-ip>:9090 interface. Verify on the `Status->targets` menu that both your `cardano` and `node` endpoints are up.

On your firewall configuration, you don't need to open the 12789 and 12790 ports since thoses are fetched by the local prometheus server. But you will need to allow the `9090` port (prometheus web interface) to be accessible from your `monitoring` node to your `relay` and `block` node.

### Installing Grafana

On your `monitoring` node, create the `config/node/monitoring/grafana` folder and add `grafana.ini` file on it. If you are using your `relay` node as `monitoring` node, use the `config/relay/monitoring/grafana` folder instead.

You can fetch the [default grafana configuration file](https://raw.githubusercontent.com/grafana/grafana/master/conf/defaults.ini) for this matter and adapt it to your needs.
You don't need to spend too much time on this file, since you will be able to perform most of your configuration from the Grafana web interface.

Note that uncommenting the `;http_port = 3000` line will allow you to choose your port.
If you have a `https` certificate, add the files to the configuration folder and configure `https` as the default protocol of Grafana (from /config/) folder. It's also possible to [configure Grafana with let's encrypt](https://blog.hackzenwerk.org/2019/05/13/setup-grafana-on-ubuntu-18-04-with-letsencrypt/), but that's out of the scope of this tutorial. Don't hesitate to modify the scripts on this repo for that.

You can now run your grafana server with

    ./deploy-configuration.sh node # use ./deploy-configuration relay if using your relay node
    ./cardano-sell.sh grafana

This will launch grafana in the cardano-shell container. As usual with docker, use `<ctrl>+P <ctrl>+Q` to detach.

You can now access the Grafana web interface from `http://<monitoring-node-ip>:<grafana-port>`

From the web interface, add your prometheus urls as datasources: from the menu, select the `settings` icon and click on the `Data Sources` submenu. Then click on the `Add data source` submenu. Select `Prometheus`, then enter the prometheus web url (without a trailing slash: `http://<relay-ip>:<prometheus-port>`) of your relay node. Keep 'Server' access. Set `prometheus-relay` as name for this datasource. Validate. Repeat the operation with the block node, with `prometheus-block` as name for the datasource.

Now that both your datasources are added to Grafana, the last step is to configure your dahsboard. From the [Cardano ops repository](https://raw.githubusercontent.com/input-output-hk/cardano-ops/ea161f35792e74b41efa749085ead64c901f784d/modules/grafana/cardano/cardano-application-dashboard-v2.json), fetch the cardano-application-dashboard-v2.json file. It's a nice preconfiguration.

Edit it, find and replace all occurences of the `"datasource": "prometheus",` string and replace with `"datasource": "prometheus-relay",`. At the end of the file, change the `title` field with your Dashboard title for the relay node, and change the `uid` field to something unique.

You can now import the Dashboard by cliquing on the `+` icon -> import.

Repeat the same operation for the `block` dashboard, changing datasources to `"datasource": "prometheus-block",`, and selecting a different `title` and `uid` fields.

On your new dashboards, you should see incoming data within 1 minute.

## Topology auto-update

Configuring a static node will put your node at risk to be disconnected from the main network if your "relay" nodes are disconnected for long enough.

To avoid this situation, most stake pool operators use a script to update the `topology.json` file on a daily or hourly basis.

cardano-shell-docker implements a auto-updating topology option. To use it on the relay, instead of the `./cardano-shell.sh relay` command to launch the relay node, use:

    ./cardano-shell.sh relay autotopology

Launching shell with the autotopology option will make it add a crontab to run the `/cmd/topologyUpdater.sh` script every day.

This script fetch 20 relay nodes from adapools, and add on top whatever you placed on the `/config/{node|relay}/base-topology.json` file (respect the same format than mainnet-topology.json).

You can also test it on your local node with the following:

    ./cardano-shell node autotopology

In the new shell, try `crontab -l` command to see if the crontask is correctly defined. You can also run `/cmd/topologyUpdater.sh` manually and `cat /config/mainnet-topology.json` to verify that your block-producing node and the IOHK relay are present.

## Firewalling

Most providers will provide a firewall interface to filter traffic from and to your nodes. However, if it's not the case, you can use `iptables`. If you don't know how to use it, there are many excellent ressources on the internet. [Here is one](https://www.linode.com/docs/security/firewalls/control-network-traffic-with-iptables/). Note that this must not be configured in the cardano-shell docker environment, but in the host machine.

Here are the rules that we want to allow (according to your config):

    On relay:
        Inbound:
            All ICMP traffic
            All TCP traffic to [ssh port]
            All TCP traffic to [cardano-node port]
            All TCP traffic to [grafana-web-interface port]
        Outbound:
            All ICMP traffic
            All TCP traffic
            All UDP traffic

    On block:
        Inbound:
            All TCP traffic to [ssh port] # unless you have a fixed ip to operate from
            [relay ip] TCP traffic to [cardano-node port]
            [relay ip] TCP traffic to [prometheus port]

        Outbound:
            All ICMP traffic
            All TCP traffic
            All UDP traffic

On a security matter, note that it may be a good idea to change all default ports, to complicate service identifications. Attackers usually need to identify what service your machine is running, to be able to build attacks (brute force, exploit attack, DoS, misconfiguration abuse, etc), using [fingerprinting techniques with tools like nmap](https://nmap.org/book/vscan.html). Changing default port helps to complicate this process, and also helps against attacks scanning randomly ip-ranges for service-specific vulnerability.

# Thanks and Support

If you would like to support this project:
- deleguate to stakepool.fr pool [ticker: SPFR]
- Donations are also appreciated:
  - ADA: DdzFFzCqrht8ZdbpE6zKwNegme7TjAtVBw2t4abuqRshNhobiAw3ND5NuC5fhuHhPg8LTk5wX5BdgZXYrqwfnnfncfafyzbrE7zdPBz5
  - BTC: 1NmoNTcA1qRannogf1ycHqte6cYqLvZSEo
  - ETH: 0xa2d717472e7de75a3b46f96d3fcfd1ff861be895

Shoutout to [abracadaniel](https://github.com/abracadaniel/cardano-node-docker) for his work (providing a good base).
