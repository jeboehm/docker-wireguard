#!/bin/sh
set -e

start() {
    for conf in /etc/wireguard/wg*.conf
    do
        interface=$(basename ${conf} .conf)
        echo "Starting WireGuard for ${interface}"
        wg-quick up ${conf}
    done
}

stop() {
    for conf in /etc/wireguard/wg*.conf
    do
        interface=$(basename ${conf} .conf)
        echo "Stopping WireGuard for ${interface}"
        wg-quick down ${conf}
    done
}

start
trap stop TERM INT QUIT

/usr/local/bin/prometheus_wireguard_exporter ${EXPORTER_CMD_ARGS:-}
