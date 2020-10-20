# Cardano-shell-docker: docker-based image to run a stakepool

Cardano-shell-docker is an collection of utilities to simplify access to cardano-node and cardano-cli from a docker environment. No need to install from source, with specific version of ghc, libsodium and other specific libraries and build tools that might hard to build on your system, or that could break your package manager dependencies.

`DISCLAIMER`: I share my own work for free without any kind of warranty. **Use these tools at your own risk**.

`SECURITY NOTE`: From a security perspective, **you should always read the source of the docker images and scripts that you use**, especially when handling financial assets.

`WARNING`: Currently under construction. This project (under construction) is using bash. Windows is not officially supported.

# Installation / setup of cardano-shell

Install [docker](https://docs.docker.com/get-docker/), clone this project, then run:

    $ docker build . -t cardano-shell

On Linux/Mac, from the root of the project, make the utility scripts executables with:

    $ chmod +x *.sh

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

    $ ./deploy-configuration.sh

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

<details>
<summary>Expand if you need to understand what are the different files</summary>
Generation procedures for keys and addresses usually output 3 files:
- file.skey: private signing key, SHOULD NEVER BE ONLINE
- file.vkey: public verification key, used in many procedures. Keep it offline too for best security
- file.addr: address corresponding to the key pair generated. Could be public if needed.

You'll generate a payment keypair/address, to honor your stakepool pledge, and a stake keypair/address, that will receive the rewards for your participation in the cardano blockchain.

Recommandation: Backup theses 3 files to a seperate secure location, never put it online (at least unencrypted).
</details>

## Generating payment keys/address and stake keys/address

<details>
<summary>Expand for detailed procedure</summary>
This procedure is for shelley mainnet. For testnet, replace in following commands `--mainnet` with `--testnet-magic 42`.

From `local` do the following:

launch a cardano-shell:

    ./cardano-shell.sh

In the shell, create a folder to hold our keys:

    mkdir -p /config/keys

generate the payment key pair:

    cardano-cli shelley address key-gen \
      --verification-key-file config/keys/payment.vkey \
      --signing-key-file config/keys/payment.skey

generate the stake key pair:

    cardano-cli shelley stake-address key-gen \
      --verification-key-file stake.vkey \
      --signing-key-file stake.skey

build the payment address:

    cardano-cli shelley address build \
      --payment-verification-key-file /config/keys/payment.vkey \
      --stake-verification-key-file /config/keys/stake.vkey \
      --out-file /config/keys/payment.addr \
      --mainnet

build the stake address:

    cardano-cli shelley stake-address build \
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

</details>

## Registering the stake address in the blockchain

<details>
<summary>Expand for detailed procedure</summary>
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

    cardano-cli shelley stake-address registration-certificate \
      --stake-verification-key-file /config/keys/stake.vkey \
      --out-file /config/keys/stake.cert

From the `local` shell, copy it to our backup folder:

    sudo cp docker/config/keys/stake.cert .backup/secret/keys/
    sudo chmod 400 .backup/secret/keys/stake.cert

Now, we need to know how much ada we need to send to our payment address. First, go on the cardano-shell a check what are the protocol amounts:

    # mkdir /work
    # cd /work
    # cardano-cli shelley query protocol-parameters \
        --mainnet \
        --out-file protocol.json
    # grep keyDeposit protocol.json
        "keyDeposit": 2000000,

Here, we have to make a deposit of 2 million lovelaces, which is 2 ADA, in addition to the transaction fees.

Following the [cardano transaction tutorial](https://cardano-foundation.gitbook.io/stake-pool-course/stake-pool-guide/stake-key/register_key), we're going to draft our transaction and determine all the parameters.

First, query the current utx0 balance using the bashrc alias `sp-balance` or:

    # cardano-cli shelley query utxo --address $(cat /config/keys/payment.addr) --mainnet
    TxHash                                                               TxIx      Lovelace
    98952480a220f83947fec475c2ff6c4327a18d2798a04fnuv1c49eab307224d8     0         100000000

From theses information, we get our UTX0 number, or TxIx and our current lovelace amount (ada amount * 1000000). In this example, we have `100 ada` so it's `100 millions lovelaces`.

First, draft our transaction with these parameters (leaving 0 for the info we don't have yet). Make sure to include the TxIx after the `#`. Save this command in a notepad as we will rework it later.

    cardano-cli shelley transaction build-raw \
      --tx-in 98952480a220f83947fec475c2ff6c4327a18d2798a04fnuv1c49eab307224d8#0 \
      --tx-out $(cat /config/keys/payment.addr)+0 \
      --ttl 0 \
      --fee 0 \
      --out-file tx.raw \
      --certificate-file /config/keys/stake.cert

Then query the TTL using `sp-ttl` alias or:

    # cardano-cli shelley query tip --mainnet
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

    # cardano-cli shelley transaction calculate-min-fee \
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

    cardano-cli shelley transaction build-raw \
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

    cardano-cli shelley transaction sign \
      --tx-body-file tx.raw \
      --signing-key-file /config/keys/payment.skey \
      --signing-key-file /config/keys/stake.skey \
      --mainnet \
      --out-file tx.signed

You should now have a `tx.signed` file in your local folder. Submit the transaction to the blockchain:

    cardano-cli shelley transaction submit \
      --tx-file tx.signed \
      --mainnet

And voila! Now, we can query with `sp-balance` our balance to see if the fees and deposit have been paid, meaning the transaction has been successfully executed by the blockchain.

Note that if you meet [BadInputsUTxO](https://iohk.zendesk.com/hc/en-us/articles/900001210346-Transactions-errors-BadInputsUTxO-) or [ValueNotConservedUTxO](https://iohk.zendesk.com/hc/en-us/articles/900001220843-Transaction-errors-ValueNotConservedUTxO), it means that you made some mistakes with the parameters. Please check them out again.

When done, don't forget to delete the keys from your docker directory:

    sudo rm -rf docker/config/keys/*.skey
    sudo rm -rf docker/config/keys/*.vkey

</details>

## Generate our stake pool keys and certificate

<details>
<summary>Expand for detailed procedure</summary>

On your `local` machine, perform the following procedure.

Start a shell with node:

    ./cardano-shell.sh node

Generate cold keys for your stakepool:

    cardano-cli shelley node key-gen \
      --cold-verification-key-file /config/keys/cold.vkey \
      --cold-signing-key-file /config/keys/cold.skey \
      --operational-certificate-issue-counter-file /config/keys/cold.counter

Generate a VRF keypair:

    cardano-cli shelley node key-gen-VRF \
    --verification-key-file /config/keys/vrf.vkey \
    --signing-key-file /config/keys/vrf.skey

Generate a [KES](https://cardano-foundation.gitbook.io/stake-pool-course/stake-pool-guide/stake-pool/kes_period) keypair:

    cardano-cli shelley node key-gen-KES \
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

    cardano-cli shelley node issue-op-cert \
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

</details>

Save your stakepool.zip archive to a cold secure location.

## Configure the relay and block-producer nodes

<details>
<summary> Expand for detailed procedure </summary>

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

</details>

## Register the stakepool metadata

<details>
<summary>Expand for detailed procedure</summary>

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

    cp metadata.json docker/config/

Then from your local cardano-shell, get the hash:

    cardano-cli shelley stake-pool metadata-hash --pool-metadata-file /config/metadata.json

Finally, we are able to create our stakepool registration certificate. Choose your:
- pool pledge (amount that you will stake. YOU MUST HONOR YOUR PLEDGE)
- pool cost (cost of running your pool)
- pool margin (% of rewards)

Once you decide those numbers (in lovelace), copy the necessary key files to your docker config

    sudo cp .backup/secret/keys/cold.vkey docker/config/keys/
    sudo cp .backup/secret/keys/vrf.vkey docker/config/keys/
    sudo cp .backup/secret/keys/stake.vkey docker/config/keys/

then create you docker certificate:

    cardano-cli shelley stake-pool registration-certificate \
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

    cardano-cli shelley stake-address delegation-certificate \
        --stake-verification-key-file /config/keys/stake.vkey \
        --cold-verification-key-file /config/keys/cold.vkey \
        --out-file /config/keys/delegation.cert

Once node, backup this file in our backup folder (from our local shell):

    sudo cp docker/config/keys/pool-registration.cert .backup/secret/keys/
    sudo cp docker/config/keys/delegation.cert .backup/secret/keys/
    sudo chmod 400 .backup/secret/keys/pool-registration.cert
    sudo chmod 400 .backup/secret/keys/delegation.cert

Now, we need to submit our pool-registration.cert and delegation.cert to the blockchain.

Create a work directory for the transaction, get protocol.json and check what our pool deposit needs to be.

    # mkdir /work
    # cd /work
    # cardano-cli shelley query protocol-parameters --mainnet --out-file protocol.json
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

    cardano-cli shelley transaction build-raw \
        --tx-in <utxo number>#<txix> \
        --tx-out $(cat /config/keys/payment.addr)+0 \
        --ttl 0 \
        --fee 0 \
        --out-file tx.raw \
        --certificate-file /config/keys/pool-registration.cert \
        --certificate-file /config/keys/delegation.cert

For calculating the min fee, we will use a witness count of 3 (since we will sign with payment.skey, stake.skey and cold.skey).

    cardano-cli shelley transaction calculate-min-fee \
        --tx-body-file tx.raw \
        --tx-in-count 1 \
        --tx-out-count 1 \
        --mainnet \
        --witness-count 3 \
        --byron-witness-count 0 \
        --protocol-params-file protocol.json


Then, using `expr <mybalance> - 500000000 - <minfees>`, we can deduct the remaining amount, and build the full request, which will look like this:

    cardano-cli shelley transaction build-raw \
        --tx-in <utxo number>#<txix> \
        --tx-out $(cat /config/keys/payment.addr)+<remaining_amount> \
        --ttl <current slotNo + 50000> \
        --fee <minfee> \
        --out-file tx.raw \
        --certificate-file /config/keys/pool-registration.cert \
        --certificate-file /config/keys/delegation.cert

Once this is done, sign the transaction:

    cardano-cli shelley transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file /config/keys/payment.skey \
        --signing-key-file /config/keys/stake.skey \
        --signing-key-file /config/keys/cold.skey \
        --mainnet \
        --out-file tx.signed

And finally, submit it to the blockchain:

    cardano-cli shelley transaction submit \
        --tx-file tx.signed \
        --mainnet

Check with `sp-balance` if your amount was deducted from your payment address. If so, congratulation, your stakepool is not registered to the blockchain! You can check on adapools.org if you can see it.

You can also check on cardano-cli. Get your pool id with:

    cardano-cli shelley stake-pool id --verification-key-file /config/keys/cold.vkey

Then:

    cardano-cli shelley query ledger-state --mainnet | grep publicKey | grep <poolid>

should return a non-empty string.

Save your poolid into the backup directory:

    echo <poolid> > poolid
    sudo mv poolid .backup/secret/keys/

Now we can delete your keys from our node folder:

    sudo rm docker/config/keys/*.skey
    sudo rm docker/config/keys/*.vkey

Create a .zip encrypted backup for your config folder, and save it somewhere safe.

    sudo zip --encrypt .backup/secret/stakepool.zip docker/config/keys/

</details>

## Update the stakepool parameters

<details>
<summary>Expand for detailed procedure</summary>

Over time, you'll gather more funds. You might want to change your pledge, your margin, or some of your metadata.

Proceed like for the initial pool registration, but this time you don't have to pay deposit fees.

</details>

## Install Monitoring (Prometheus and Grafana)

Prometheus allows to fetch and graph application metrics, Grafana is
a very nice interface to display and organize all of them.

Best practice is to have a specific `monitoring` node. If you don't want to run one more serveur, use your `relay` node if you want to have your monitoring available from anywhere, as it does not host sensitive files and operations.
You can also use your `local` node, but if it's not available and connected 24/7, you wont be able to configure efficient alerts.

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

<!-- ## Topology auto-updating

Configuring a static node will put your node at risk to be disconnected from the main network if your "relay" nodes are disconnected for long enough. -->

# Thanks and Support

If you would like to support the maintainance of this project:
- deleguate to stakepool.fr pool [SPFR]
- install Brave browser from my [referral link](https://brave.com/sna144). It's a privacy-oriented ad-blocking browser forked from chrome, that let you mine cryptocurrency if you accept ads.
- Donations are also appreciated:
  - ADA: DdzFFzCqrht8ZdbpE6zKwNegme7TjAtVBw2t4abuqRshNhobiAw3ND5NuC5fhuHhPg8LTk5wX5BdgZXYrqwfnnfncfafyzbrE7zdPBz5
  - BTC: 1NmoNTcA1qRannogf1ycHqte6cYqLvZSEo
  - ETH: 0xa2d717472e7de75a3b46f96d3fcfd1ff861be895


Shoutout to [abracadaniel](https://github.com/abracadaniel/cardano-node-docker) for his work (providing a good base).