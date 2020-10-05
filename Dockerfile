from inputoutput/cardano-node
LABEL maintainer="seb@stakepool.fr"
SHELL ["/bin/bash", "-c"]

# Install dependencies
#RUN apt-get update -y \
#    && apt-get install -y find wget grep \
#    && apt-get clean

# Expose ports
## cardano-node, EKG, Prometheus
EXPOSE 3000 12788 12798

# Add path for cardano-node to PATH
ENV PATH="$PATH:/nix/store/b2dysryvhkd79qygbgw5agyvk96wlmjg-cardano-node-exe-cardano-node-1.20.0/bin/"

ENTRYPOINT ["/bin/bash", "-l", "-c"]
