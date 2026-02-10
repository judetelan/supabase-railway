#!/bin/sh
set -e

echo "=== Studio Auth Proxy Starting ==="

# Set defaults for auth credentials
STUDIO_USER="${STUDIO_USERNAME:-admin}"
STUDIO_HASH="${STUDIO_PASSWORD_HASH:-\$2b\$14\$uWXyevN6Gn9fldzBLb.ty.SN4.aWp8blmrKeIosUvQaCji8rlft6q}"

echo "Auth user: $STUDIO_USER"

# Generate Caddyfile from template with actual credentials
sed -e "s|STUDIO_USER|${STUDIO_USER}|g" \
    -e "s|STUDIO_HASH|${STUDIO_HASH}|g" \
    /etc/caddy/Caddyfile.template > /etc/caddy/Caddyfile

echo "Caddyfile generated."

# Start Caddy on port 3000 first (fast startup, handles health checks immediately)
echo "Starting Caddy auth proxy on port 3000..."
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!

# Give Caddy a moment to bind port 3000
sleep 1

# Start Studio on internal port 3001
echo "Starting Studio on port 3001..."
PORT=3001 node /app/server.js &
STUDIO_PID=$!

# Wait for Studio to be ready
echo "Waiting for Studio to be ready..."
for i in $(seq 1 60); do
    if wget -q --spider http://localhost:3001/api/platform/profile 2>/dev/null; then
        echo "Studio is ready on port 3001."
        break
    fi
    sleep 1
done

echo "=== Studio Auth Proxy Ready ==="

# Wait for either process to exit
wait $CADDY_PID $STUDIO_PID
