FROM mindflavor/prometheus-wireguard-exporter:3.6.4 AS prometheus-wireguard-exporter
FROM alpine:3

RUN apk add --no-cache wireguard-tools iptables net-tools iproute2

COPY rootfs /
COPY --from=prometheus-wireguard-exporter /usr/local/bin/prometheus_wireguard_exporter /usr/local/bin/prometheus_wireguard_exporter

EXPOSE 9586

CMD ["/usr/local/bin/entrypoint.sh"]
