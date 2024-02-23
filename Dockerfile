# Build main website
FROM klakegg/hugo:0.93.2 as builder
WORKDIR /build
COPY . .
RUN hugo

# Build Go vanity URL
FROM golang:1.21 as vanity_builder
WORKDIR /build
COPY . .
WORKDIR vanity
RUN go run generator.go

# Download Caddy binary from GitHub releases
FROM ubuntu:22.04 as caddy_downloader
WORKDIR /dl
RUN apt update && apt install -y curl
RUN curl -sL -o caddy_2.7.6_linux_amd64.tar.gz https://github.com/caddyserver/caddy/releases/download/v2.7.6/caddy_2.7.6_linux_amd64.tar.gz
RUN tar -xzf caddy_2.7.6_linux_amd64.tar.gz && mv caddy /usr/local/bin

FROM ubuntu:22.04
RUN apt update && apt install -y tzdata net-tools sqlite3 && apt clean
COPY --from=caddy_downloader /usr/local/bin/caddy /usr/local/bin/caddy
COPY --from=builder /build/public /usr/share/caddy/wperron.io
COPY --from=vanity_builder /build/vanity/public /usr/share/caddy/go.wperron.io
COPY --from=builder /build/Caddyfile /etc/caddy/Caddyfile
