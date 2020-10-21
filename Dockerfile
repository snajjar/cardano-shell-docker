from arradev/cardano-node
LABEL maintainer="contact@stakepool.fr"
SHELL ["/bin/bash", "-c"]

# ENV variables
ENV PATH="/root/.cabal/bin:/scripts:/scripts/functions:/cardano-node/scripts:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

# Remove /etc/profile, so it doesn't mess up our PATH env
RUN rm /etc/profile

# Install monitoring tools
RUN apt-get update -y \
    && apt-get install -y htop unzip grc dbus prometheus prometheus-node-exporter software-properties-common node.js npm \
    && apt-get clean

# Install Grafana
RUN curl https://packages.grafana.com/gpg.key | apt-key add - \
    && add-apt-repository "deb https://packages.grafana.com/oss/deb stable main" \
    && apt-get update \
    && apt-get install -y grafana \
    && apt-get clean

# Install PM2: process manager to auto-restart prometheus-node-exporter of grafana on crash
RUN npm install -g pm2

# Expose ports
## cardano-node, EKG, Prometheus
EXPOSE 3000 12788 12798 13006 13007

ENTRYPOINT ["/bin/bash", "-l"]
