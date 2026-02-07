#BUILD THE RCON-CLI PACKAGE
FROM golang:1.23.1-alpine AS rcon-cli_builder

ARG RCON_VERSION="0.10.3"
ARG RCON_TGZ_SHA1SUM=33ee8077e66bea6ee097db4d9c923b5ed390d583

WORKDIR /build

# install rcon
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ENV CGO_ENABLED=0
RUN wget -q https://github.com/gorcon/rcon-cli/archive/refs/tags/v${RCON_VERSION}.tar.gz -O rcon.tar.gz \
    && echo "${RCON_TGZ_SHA1SUM}" rcon.tar.gz | sha1sum -c - \
    && tar -xzvf rcon.tar.gz \
    && rm rcon.tar.gz \
    && mv rcon-cli-${RCON_VERSION}/* ./ \
    && rm -rf rcon-cli-${RCON_VERSION} \
    && go build -v ./cmd/gorcon

#BUILD THE SERVER IMAGE
FROM cm2network/steamcmd:root

RUN apt-get update && apt-get install -y --no-install-recommends \
    gettext-base \
    procps \
    jq \
    libarchive-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=rcon-cli_builder /build/gorcon /usr/bin/rcon-cli

LABEL maintainer="support@indifferentbroccoli.com" \
      name="indifferentbroccoli/rust-server-docker" \
      github="https://github.com/indifferentbroccoli/rust-server-docker" \
      dockerhub="https://hub.docker.com/r/indifferentbroccoli/rust-server-docker"

ENV HOME=/home/steam \
    SERVER_PORT=28015 \
    RCON_PORT=28016 \
    APP_PORT=28082 \
    SERVER_NAME=rustserver \
    SERVER_DESCRIPTION="Welcome to your Indifferent Broccoli Rust server" \
    SERVER_SEED=12345 \
    WORLD_SIZE=3500 \
    MAX_PLAYERS=50 \
    GENERATE_SETTINGS=true \
    OXIDE_ENABLED=false

COPY ./scripts /home/steam/server/

COPY branding /branding

RUN mkdir -p /steamcmd/rust && \
    chmod +x /home/steam/server/*.sh && \
    chmod +x /home/steam/server/rcon && \
    ln -s /home/steam/server/rcon /usr/bin/rcon && \
    chown -R steam:steam /steamcmd/rust
WORKDIR /home/steam/server

HEALTHCHECK --start-period=5m \
            CMD pgrep "RustDedicated" > /dev/null || exit 1

ENTRYPOINT ["/home/steam/server/init.sh"]
