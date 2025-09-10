#!/bin/sh
set -e

start() {
    for conf in /etc/wireguard/wg*.conf
    do
        interface=$(basename ${conf} .conf)
        echo "Starting WireGuard for ${interface}"
        wg-quick up ${conf}

        # Check if there's an environment variable for the private key
        env_var_name="WIREGUARD_$(echo ${interface} | tr '[:lower:]' '[:upper:]')_PRIVATE_KEY"
        private_key=$(eval echo \$${env_var_name})

        if [ -n "${private_key}" ]; then
            echo "Using private key from environment variable ${env_var_name}"
            wg set ${interface} private-key <(echo "${private_key}")
        fi
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
