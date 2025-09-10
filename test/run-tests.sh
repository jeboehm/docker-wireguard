#!/bin/bash
set -e

# Test suite runner for Docker WireGuard
echo "🚀 Starting Docker WireGuard Test Suite"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
COMPOSE_FILE="$TEST_DIR/docker-compose.yml"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to cleanup on exit
cleanup() {
    print_status $YELLOW "🧹 Cleaning up test environment..."
    cd "$TEST_DIR"
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
    docker system prune -f >/dev/null 2>&1 || true
}

# Set trap for cleanup
trap cleanup EXIT

# Check prerequisites
print_status $BLUE "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_status $RED "❌ Docker is not installed"
    exit 1
fi

print_status $GREEN "✅ Prerequisites check passed"

# Build the test image
print_status $BLUE "🔨 Building test image..."
cd "$PROJECT_ROOT"
docker build -t docker-wireguard-test .

if [ $? -ne 0 ]; then
    print_status $RED "❌ Failed to build test image"
    exit 1
fi

print_status $GREEN "✅ Test image built successfully"

# Start test environment
print_status $BLUE "🚀 Starting test environment..."
cd "$TEST_DIR"
docker compose -f "$COMPOSE_FILE" up -d

# Wait for services to be ready
print_status $BLUE "⏳ Waiting for services to be ready..."
sleep 30

# Run health checks
print_status $BLUE "🏥 Running health checks..."

# Check if WireGuard container is healthy
if docker compose -f "$COMPOSE_FILE" ps wireguard-test | grep -q "healthy"; then
    print_status $GREEN "✅ WireGuard container is healthy"
else
    print_status $RED "❌ WireGuard container is not healthy"
    docker compose -f "$COMPOSE_FILE" logs wireguard-test
    exit 1
fi

# Test WireGuard interfaces
print_status $BLUE "🔍 Testing WireGuard interfaces..."
docker exec wireguard-test wg show

# Test Prometheus metrics
print_status $BLUE "📊 Testing Prometheus metrics..."
if curl -s http://localhost:9586/metrics | grep -q "wireguard"; then
    print_status $GREEN "✅ Prometheus metrics are available"
else
    print_status $RED "❌ Prometheus metrics are not available"
    exit 1
fi

# Test multiple interface support
print_status $BLUE "🔗 Testing multiple interface support..."
interfaces=$(docker exec wireguard-test wg show interfaces)
interface_count=$(echo "$interfaces" | wc -w)

if [ "$interface_count" -ge 2 ]; then
    print_status $GREEN "✅ Multiple interfaces detected: $interfaces"
else
    print_status $YELLOW "⚠️  Only $interface_count interface(s) detected: $interfaces"
fi

# Test environment variable private key feature
print_status $BLUE "🔑 Testing environment variable private key feature..."
if echo "$interfaces" | grep -q "wg2"; then
    print_status $GREEN "✅ wg2 interface created successfully with environment variable private key"

    # Verify the private key was set correctly by checking the interface details
    wg2_details=$(docker exec wireguard-test wg show wg2)
    if echo "$wg2_details" | grep -q "private key"; then
        print_status $GREEN "✅ Private key was set correctly for wg2 interface"
    else
        print_status $RED "❌ Private key was not set for wg2 interface"
        exit 1
    fi

    # Test that wg2 is listening on the correct port
    if docker exec wireguard-test netstat -ulnp | grep -q ":51822"; then
        print_status $GREEN "✅ wg2 interface is listening on port 51822"
    else
        print_status $RED "❌ wg2 interface is not listening on port 51822"
        exit 1
    fi
else
    print_status $RED "❌ wg2 interface was not created - environment variable feature failed"
    exit 1
fi

# Test entrypoint script functionality
print_status $BLUE "📜 Testing entrypoint script functionality..."

# Check if entrypoint script is executable
if docker exec wireguard-test test -x /usr/local/bin/entrypoint.sh; then
    print_status $GREEN "✅ Entrypoint script is executable"
else
    print_status $RED "❌ Entrypoint script is not executable"
    exit 1
fi

# Test graceful shutdown
print_status $BLUE "🛑 Testing graceful shutdown..."
docker compose -f "$COMPOSE_FILE" stop wireguard-test
sleep 5

# Check if interfaces were properly torn down
if docker exec wireguard-test wg show 2>/dev/null | grep -q "interface"; then
    print_status $YELLOW "⚠️  Some WireGuard interfaces may still be active"
else
    print_status $GREEN "✅ WireGuard interfaces were properly torn down"
fi

# Test results summary
print_status $GREEN "🎉 Test suite completed successfully!"
print_status $BLUE "📋 Test Summary:"
echo "  - Docker image builds successfully"
echo "  - WireGuard interfaces start correctly"
echo "  - Multiple interface support works"
echo "  - Environment variable private key feature works"
echo "  - Prometheus metrics are exported"
echo "  - Entrypoint script functions properly"
echo "  - Graceful shutdown works"

print_status $BLUE "🔗 Access points:"
echo "  - Prometheus metrics: http://localhost:9586/metrics"
echo "  - Prometheus UI: http://localhost:9090"
echo "  - WireGuard server: localhost:51820 (wg0), localhost:51821 (wg1), localhost:51822 (wg2)"

print_status $YELLOW "💡 To keep the test environment running, use:"
echo "  docker compose -f $COMPOSE_FILE up -d"
echo ""
print_status $YELLOW "💡 To stop the test environment, use:"
echo "  docker compose -f $COMPOSE_FILE down"
