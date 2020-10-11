# Cardano-shell: docker-based cardano-cli and cardano-node to set up a staking pool

Cardano-shell is an utility to simplify access to cardano-node and cardano-cli from a docker environment. No need to install from source, with specific version of ghc, libsodium and other specific libraries and build tools that might break your package manager dependencies.

DISCLAIMER: I share my own work for free without any kind of warranty. **Use these tools at your own risk**.

SECURITY: From a security perspective, **you should always read the source of the docker images and scripts that you use**, especially when handling financial assets.

WARNING: Project currently under construction. Windows currently not supported (local scripts need adjustments).

# Installation / setup of cardano-shell

Install [docker](https://docs.docker.com/get-docker/), clone this project, then run:

    $ docker build . -t cardano-shell

On Linux/Mac, from the root of the project, make the utility scripts executables with:

    $ chmod +x *.sh

# Launching a cardano-shell

To launch a shell able to run cardano-cli:

    $ ./cardano-shell.sh

If you want to run cardano-cli commands that needs to have a running node, first edit configuration files on the **config/node** directory, then copy them to the docker directory with

    $ ./deploy-configuration.sh

After that, you can launch a container with a running node and an open shell with:

    $ ./cardano-shell-with-node.sh

# Building a stake pool with cardano-shell

For that matter, the recommanded configuration is 3 hosts:
- 1 online relay node, we'll call it `relay`.
- 1 online block-producing node, we'll call is `block`
- 1 *local* host to securely create keys, and sign transactions with it. We'll call it `local`.

**For best security**, the keys creations and transactions signing should be done on a completely offline host.

**For a reasonable security/usability tradeoff**, run theses commands on a secured, firewalled host (that could be your local machine), that you are positive that it was never compromised.



<details>
<summary>## Understanding keys and addresses files</summary>
Generation procedures for keys and addresses usually output 3 files:
- file.skey: private signing key, SHOULD NEVER BE ONLINE
- file.vkey: public verification key, used in many procedures. Keep it offline too for best security
- file.addr: address corresponding to the key pair generated. Could be public if needed.

You'll generate a payment keypair/address, to honor your stakepool pledge, and a stake keypair/address, that will receive the rewards for your participation in the cardano blockchain.

Recommandation: Backup theses 3 files to a seperate secure location, never put it online (at least unencrypted).
</details>

## Generating payment keys/address and stake keys/address

<details>

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

    mkdir .backup
    cp -r ./docker/config/keys .backup
    sudo chown -R root .backup
    sudo chmod -R 400 .backup

Create a encrypted archive that you'll backup somewhere. Don't hesitate to [gpg encrypt](https://linuxconfig.org/how-to-encrypt-and-decrypt-individual-files-with-gpg) it if your gpg keys are already securely backed up. Here's a simple way to create an encrypted archive:

     sudo zip --encrypt .backup/stakepool.zip docker/config/keys/

Remember not to use --password (zip) or --passphrase (gpg) or similar options, as the password would be stored in plain text in the shell history and in system memory. If you absolutely have to, use `set -o history` to turn off history, and `set +o history` to turn it back on.

Finally, close the cardano-shell and verify that the container is stopped and deleted with `docker list containers` and `docker list containers -a`.
Once done, delete the config/keys folders:

    rm -rf ./docker/config/keys/

</details>

## Registering the strage address in the blockchain

