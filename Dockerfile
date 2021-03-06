FROM debian:stable-slim

# version of cardano-node to build
ARG CARDANO_NODE_VERSION=1.27.0
ARG CNCLI_VERSION=2.0.3
ARG GHC_VERSION=8.10.4

# based on arradev/cardano-node
LABEL maintainer="contact@stakepool.fr"
SHELL ["/bin/bash", "-c"]

# Install software-properties-common to get add-apt-repository command
RUN apt-get update -y && apt-get install -y software-properties-common && apt-get clean

# Install build dependencies
RUN apt-get update -y \
    && apt-get install -y automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ \
    tmux git jq wget gpg libncursesw5 libtool autoconf vim procps dnsutils bc curl nano cron python3 python3-pip htop unzip grc dbus prometheus \
    prometheus-node-exporter software-properties-common node.js npm daemontools \
    && apt-get clean

RUN pip3 install pytz

# Install PM2: process manager to auto-restart prometheus-node-exporter of grafana on crash
RUN npm install -g pm2

# Install Grafana
RUN curl https://packages.grafana.com/gpg.key | apt-key add - \
    && add-apt-repository "deb https://packages.grafana.com/oss/deb stable main" \
    && apt-get update \
    && apt-get install -y grafana \
    && apt-get clean


# ENV variables
ENV NODE_PORT="3000" \
    NODE_NAME="node1" \
    NODE_TOPOLOGY="" \
    NODE_RELAY="False" \
    CARDANO_NETWORK="main" \
    EKG_PORT="12788" \
    PROMETHEUS_HOST="127.0.0.1" \
    PROMETHEUS_PORT="12798" \
    RESOLVE_HOSTNAMES="False" \
    REPLACE_EXISTING_CONFIG="False" \
    POOL_PLEDGE="100000000000" \
    POOL_COST="10000000000" \
    POOL_MARGIN="0.05" \
    METADATA_URL="" \
    PUBLIC_RELAY_IP="TOPOLOGY" \
    WAIT_FOR_SYNC="True" \
    AUTO_TOPOLOGY="True" \
    PATH="/root/.cabal/bin/:/scripts/:/scripts/functions/:/cardano-node/scripts/:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}" \
    CARDANO_NODE_SOCKET_PATH="DEFAULT" \
    PATH="/root/.cabal/bin:/root/.ghcup/bin:/root/.local/bin:/scripts:/scripts/functions:/cardano-node/scripts:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

# Install cabal
RUN wget https://downloads.haskell.org/~cabal/cabal-install-3.2.0.0/cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz \
    && tar -xf cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz \
    && rm cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz cabal.sig \
    && mkdir -p ~/.local/bin \
    && mv cabal ~/.local/bin/ \
    && cabal update && cabal --version

# Install GHC
RUN wget https://downloads.haskell.org/~ghc/$GHC_VERSION/ghc-$GHC_VERSION-x86_64-deb9-linux.tar.xz \
    && tar -xf ghc-$GHC_VERSION-x86_64-deb9-linux.tar.xz \
    && rm ghc-$GHC_VERSION-x86_64-deb9-linux.tar.xz \
    && cd ghc-$GHC_VERSION \
    && ./configure \
    && make install \
    && cd / \
    && rm -rf /ghc-$GHC_VERSION

# Install libsodium
RUN git clone https://github.com/input-output-hk/libsodium \
    && cd libsodium \
    && git checkout 66f017f1 \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && cd .. && rm -rf libsodium

ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" \
    PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Install cardano-node
RUN echo "Building tags/$VERSION..." \
    && echo tags/$CARDANO_NODE_VERSION > /CARDANO_BRANCH \
    && git clone https://github.com/input-output-hk/cardano-node.git \
    && cd cardano-node \
    && git fetch --all --tags \
    && git tag \
    && git checkout ${CARDANO_NODE_VERSION} \
    && echo "Building version $VERSION" \
    && cabal build all \
    && mkdir -p /root/.cabal/bin/ \
    && find . -name cardano-node \
    && find . -name cardano-cli \
    && cp /cardano-node/dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-node-${CARDANO_NODE_VERSION}/x/cardano-node/build/cardano-node/cardano-node /root/.cabal/bin/ \
    && cp /cardano-node/dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-cli-${CARDANO_NODE_VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli /root/.cabal/bin/ \
    && rm -rf /root/.cabal/packages \
    && rm -rf /usr/local/lib/ghc-${GHC_VERSION}/ \
    && rm -rf /root/.cabal/store/ghc-${GHC_VERSION} \
    && rm -rf /cardano-node/dist-newstyle/

# Install RTView
RUN mkdir /RTView \
    && cd RTView \
    && wget https://github.com/input-output-hk/cardano-rt-view/releases/download/0.3.0/cardano-rt-view-0.3.0-linux-x86_64.tar.gz \
    && tar xzvf cardano-rt-view-0.3.0-linux-x86_64.tar.gz \
    && rm cardano-rt-view-0.3.0-linux-x86_64.tar.gz

ENV PATH="/RTView/:${PATH}"

# Remove /etc/profile, so it doesn't mess up our PATH env
RUN rm /etc/profile

# Install cncli
RUN mkdir -p $HOME/.cargo/bin \
    && chown -R $USER\: $HOME/.cargo \
    && touch $HOME/.profile \
    && chown $USER\: $HOME/.profile \
    && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y \
    && source $HOME/.cargo/env \
    && rustup install stable \
    && rustup default stable \
    && rustup update \
    && rustup component add clippy rustfmt \
    && source $HOME/.cargo/env \
    && mkdir ~/git \
    && cd ~/git \
    && git clone --recurse-submodules https://github.com/AndrewWestberg/cncli \
    && cd cncli \
    && git checkout v${CNCLI_VERSION} \
    && cargo install --path . --force \
    && cd ..

# install leaderlog script
RUN pip3 install pytz
RUN mkdir -p /scripts \
    && cd /scripts \
    && git clone https://github.com/papacarp/pooltool.io

# Add config
RUN mkdir -p /config/
VOLUME /config/
RUN mkdir -p /logs/
VOLUME /logs/

# Expose ports
## cardano-node, EKG, Prometheus
EXPOSE 3000 8090 12788 12798 13004 13005 13006 13007

ENTRYPOINT ["/bin/bash", "-l"]
