FROM debian:stable-slim

# version of cardano-node to build
ARG VERSION=1.24.2

# based on arradev/cardano-node
LABEL maintainer="contact@stakepool.fr"
SHELL ["/bin/bash", "-c"]

# Install build dependencies
RUN apt-get update -y \
    && apt-get install -y automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ \
    tmux git jq wget libncursesw5 libtool autoconf vim procps dnsutils bc curl nano cron python3 python3-pip htop unzip grc dbus prometheus \
    prometheus-node-exporter software-properties-common node.js npm \
    && apt-get clean

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
RUN wget https://downloads.haskell.org/~ghc/8.6.5/ghc-8.6.5-x86_64-deb9-linux.tar.xz \
    && tar -xf ghc-8.6.5-x86_64-deb9-linux.tar.xz \
    && rm ghc-8.6.5-x86_64-deb9-linux.tar.xz \
    && cd ghc-8.6.5 \
    && ./configure \
    && make install \
    && cd / \
    && rm -rf /ghc-8.6.5

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
    && echo tags/$VERSION > /CARDANO_BRANCH \
    && git clone https://github.com/input-output-hk/cardano-node.git \
    && cd cardano-node \
    && git fetch --all --tags \
    && git tag \
    && git checkout $VERSION \
    && echo "Building version $VERSION" \
    && cabal build all \
    && mkdir -p /root/.cabal/bin/ \
    && cp /cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.6.5/cardano-node-${VERSION}/x/cardano-node/build/cardano-node/cardano-node /root/.cabal/bin/ \
    && cp /cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.6.5/cardano-cli-${VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli /root/.cabal/bin/ \
    && rm -rf /root/.cabal/packages \
    && rm -rf /usr/local/lib/ghc-8.6.5/ \
    && rm -rf /root/.cabal/store/ghc-8.6.5 \
    && rm -rf /cardano-node/dist-newstyle/

# Install RTView
RUN mkdir /RTView \
    && cd RTView \
    && wget https://github.com/input-output-hk/cardano-rt-view/releases/download/0.2.0/cardano-rt-view-0.2.0-linux-x86_64.tar.gz \
    && tar xzvf cardano-rt-view-0.2.0-linux-x86_64.tar.gz \
    && rm cardano-rt-view-0.2.0-linux-x86_64.tar.gz

ENV PATH="/RTView/:${PATH}"

# Remove /etc/profile, so it doesn't mess up our PATH env
RUN rm /etc/profile

# Add config
RUN mkdir -p /config/
VOLUME /config/

# Expose ports
## cardano-node, EKG, Prometheus
EXPOSE 3000 12788 12798 13005 13006 13007

ENTRYPOINT ["/bin/bash", "-l"]
