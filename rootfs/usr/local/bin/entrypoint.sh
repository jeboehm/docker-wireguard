#!/bin/sh
set -e

configArgs="${EXPORTER_CMD_ARGS:-}"

start() {
    for conf in /etc/wireguard/wg*.conf
    do
        echo "Starting WireGuard for ${conf}"
        wg-quick up ${conf}

        configArgs="${configArgs} -n ${conf}"
    done
}

stop() {
    for conf in /etc/wireguard/wg*.conf
    do
        echo "Stopping WireGuard for ${conf}"
        wg-quick down ${conf}
    done
}

start
trap stop TERM INT QUIT

/usr/local/bin/prometheus_wireguard_exporter ${configArgs}
