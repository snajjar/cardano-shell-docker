from arradev/cardano-node
LABEL maintainer="seb@stakepool.fr"
SHELL ["/bin/bash", "-c"]

# Install tools
RUN apt-get update -y \
    && apt-get install -y htop unzip grc \
    && apt-get clean


# Expose ports
## cardano-node, EKG, Prometheus
EXPOSE 3000 12788 12798

# ENV variables
ENV PATH="/root/.cabal/bin/:/scripts/:/scripts/functions/:/cardano-node/scripts/:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

# Remove /etc/profile, so it doesn't mess up our PATH env
RUN rm /etc/profile

ENTRYPOINT ["/bin/bash", "-l"]
