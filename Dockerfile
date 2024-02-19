FROM klakegg/hugo:0.93.2 as builder
WORKDIR /build
COPY . .
RUN hugo

FROM caddy:2.7
RUN apk add tzdata
COPY --from=builder /build/public /usr/share/caddy
COPY --from=builder /build/Caddyfile /etc/caddy/Caddyfile
