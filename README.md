# Docker WireGuard with Prometheus Monitoring

A Docker container that provides WireGuard VPN functionality with integrated Prometheus monitoring capabilities.

## Project Purpose

This project creates a containerised WireGuard VPN server with built-in Prometheus metrics export. It's designed for:

- Running WireGuard VPN servers in containerised environments
- Monitoring VPN connections and performance through Prometheus metrics
- Easy deployment and configuration management
- Automated WireGuard interface management

## Technical Stack

- **Base Image**: Alpine Linux 3
- **VPN**: WireGuard tools and utilities
- **Monitoring**: Prometheus WireGuard Exporter (v3.6.4)
- **Container Runtime**: Docker
- **CI/CD**: GitHub Actions
- **Registry**: GitHub Container Registry (ghcr.io)

## Folder Structure

```
docker-wireguard/
├── .github/
│   └── workflows/
│       └── build.yaml          # GitHub Actions CI/CD pipeline
├── rootfs/
│   └── usr/
│       └── local/
│           └── bin/
│               └── entrypoint.sh # Container startup script
├── test/                       # Test suite and configurations
│   ├── docker-compose.yml # Test environment setup
│   ├── run-tests.sh           # Comprehensive test runner
│   ├── test-health.sh         # Container health checks
│   ├── configs/               # WireGuard server test configs
│   ├── client-configs/        # WireGuard client test configs
│   ├── prometheus.yml         # Prometheus test configuration
├── Dockerfile                   # Container build definition
└── README.md                   # Project documentation
```

## Customizations

### Entrypoint Script (`rootfs/usr/local/bin/entrypoint.sh`)
- Automatically discovers and starts all WireGuard configurations (`/etc/wireguard/wg*.conf`)
- Gracefully handles container shutdown with proper WireGuard interface cleanup
- Configures Prometheus exporter with discovered WireGuard interfaces
- Supports custom exporter arguments via `EXPORTER_CMD_ARGS` environment variable

### Container Features
- Multi-configuration support: Automatically loads all WireGuard config files
- Signal handling: Proper cleanup on container termination
- Prometheus integration: Exports metrics on port 9586
- Minimal footprint: Based on Alpine Linux

## Libraries

### Runtime Dependencies
- `wireguard-tools`: WireGuard utilities and tools
- `iptables`: Network packet filtering
- `net-tools`: Network utilities
- `iproute2`: IP routing utilities

### Monitoring
- `prometheus_wireguard_exporter`: Exports WireGuard metrics to Prometheus (v3.6.4)

## Setup Instructions

### Prerequisites
- Docker installed on your system
- WireGuard configuration files

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd docker-wireguard
   ```

2. **Prepare WireGuard configurations**:
   Place your WireGuard configuration files in a directory (e.g., `./configs/`):
   ```
   configs/
   ├── wg0.conf
   ├── wg1.conf
   └── ...
   ```

3. **Run the container**:
   ```bash
   docker run -d \
     --name wireguard \
     --cap-add=NET_ADMIN \
     --cap-add=SYS_MODULE \
     -p 51820:51820/udp \
     -p 9586:9586 \
     -v $(pwd)/configs:/etc/wireguard \
     ghcr.io/jeboehm/docker-wireguard
   ```

### Docker Compose Example

```yaml
version: '3.8'
services:
  wireguard:
    image: ghcr.io/jeboehm/docker-wireguard
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    ports:
      - "51820:51820/udp"
      - "9586:9586"
    volumes:
      - ./configs:/etc/wireguard
    environment:
      - EXPORTER_CMD_ARGS=-listen-address=0.0.0.0:9586
    restart: unless-stopped
```

### Environment Variables

- `EXPORTER_CMD_ARGS`: Additional arguments for the Prometheus exporter (optional)
  - Default: Empty
  - Example: `-listen-address=0.0.0.0:9586 -log-level=debug`

### Ports

- **51820/udp**: WireGuard VPN port (configurable via WireGuard config)
- **9586/tcp**: Prometheus metrics endpoint

### Required Capabilities

- `NET_ADMIN`: Required for network interface management
- `SYS_MODULE`: Required for WireGuard kernel module operations

## Monitoring

### Prometheus Metrics

The container exposes WireGuard metrics on port 9586. Access metrics at:
```
http://localhost:9586/metrics
```

### Example Prometheus Configuration

```yaml
scrape_configs:
  - job_name: 'wireguard'
    static_configs:
      - targets: ['wireguard:9586']
```

## Building from Source

1. **Clone and build**:
   ```bash
   git clone <repository-url>
   cd docker-wireguard
   docker build -t docker-wireguard .
   ```

2. **Run locally built image**:
   ```bash
   docker run -d \
     --name wireguard \
     --cap-add=NET_ADMIN \
     --cap-add=SYS_MODULE \
     -p 51820:51820/udp \
     -p 9586:9586 \
     -v $(pwd)/configs:/etc/wireguard \
     docker-wireguard
   ```

## Contribution Guidelines

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** following the existing code style
4. **Test your changes**:
   - Build the Docker image locally
   - Test with sample WireGuard configurations
   - Verify Prometheus metrics are working
5. **Commit your changes** using conventional commit messages:
   - `feat: add new feature`
   - `fix: resolve bug`
   - `docs: update documentation`
6. **Push to your fork** and create a pull request

### Development Setup

For local development and testing:

```bash
# Build the image
docker build -t docker-wireguard-dev .

# Run with debug output
docker run -it --rm \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -v $(pwd)/test-configs:/etc/wireguard \
  -e EXPORTER_CMD_ARGS="-log-level=debug" \
  docker-wireguard-dev
```

## Testing

### Test Suite

A test suite is available in the `test/` directory to validate the WireGuard container functionality.

#### Full Test Suite

```bash
cd test
./run-tests.sh
```

The test suite validates:
- ✅ Docker image builds successfully
- ✅ WireGuard interfaces start correctly
- ✅ Multiple interface support works
- ✅ Prometheus metrics are exported
- ✅ Entrypoint script functions properly
- ✅ Graceful shutdown works

#### Manual Testing

```bash
cd test
docker-compose -f docker-compose.yml up -d

# Check WireGuard status
docker exec wireguard-test wg show

# Check metrics
curl http://localhost:9586/metrics

# Access Prometheus UI
open http://localhost:9090
```

## Troubleshooting

### Common Issues

1. **Permission denied errors**:
   - Ensure the container has `NET_ADMIN` and `SYS_MODULE` capabilities
   - Check that WireGuard kernel module is available on the host

2. **Configuration not loading**:
   - Verify configuration files are in `/etc/wireguard/` inside the container
   - Check file permissions and format of WireGuard config files

3. **Metrics not accessible**:
   - Ensure port 9586 is exposed and accessible
   - Check firewall rules if running on a remote host

### Debug Mode

Run with debug logging:
```bash
docker run -it --rm \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -v $(pwd)/configs:/etc/wireguard \
  -e EXPORTER_CMD_ARGS="-log-level=debug" \
  ghcr.io/jeboehm/docker-wireguard
```

## License

[MIT](LICENSE)
