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

FROM caddy:2.7
RUN apk add tzdata
COPY --from=builder /build/public /usr/share/caddy/wperron.io
COPY --from=vanity_builder /build/vanity/public /usr/share/caddy/go.wperron.io
COPY --from=builder /build/Caddyfile /etc/caddy/Caddyfile
