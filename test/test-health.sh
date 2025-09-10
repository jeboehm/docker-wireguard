#!/bin/sh
set -e

# Health check script for WireGuard container
echo "Running WireGuard health checks..."

# Check if WireGuard interfaces are up
interfaces=$(wg show interfaces 2>/dev/null || echo "")
if [ -z "$interfaces" ]; then
    echo "ERROR: No WireGuard interfaces found"
    exit 1
fi

echo "Found WireGuard interfaces: $interfaces"

# Check if prometheus exporter is responding
if ! wget -q --spider http://0.0.0.0:9586/metrics; then
    echo "ERROR: Prometheus exporter not responding"
    exit 1
fi

echo "Prometheus exporter is responding"

# Check if interfaces have peers
for interface in $interfaces; do
    peers=$(wg show "$interface" peers 2>/dev/null | wc -l)
    if [ "$peers" -eq 0 ]; then
        echo "WARNING: Interface $interface has no peers"
    else
        echo "Interface $interface has $peers peer(s)"
    fi
done

echo "Health check passed"
exit 0
