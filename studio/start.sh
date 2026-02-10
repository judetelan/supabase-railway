#!/bin/sh
set -e

echo "Starting Studio with Caddy auth proxy..."

# Start Studio on internal port 3001 (explicit export overrides Railway's PORT=3000)
export PORT=3001
node /app/server.js &
STUDIO_PID=$!
export PORT=3000

# Wait for Studio to be ready
echo "Waiting for Studio to start on port 3001..."
for i in $(seq 1 30); do
    if wget -q --spider http://localhost:3001/api/platform/profile 2>/dev/null; then
        echo "Studio is ready."
        break
    fi
    sleep 1
done

# Start Caddy on port 3000 (with basic auth)
echo "Starting Caddy auth proxy on port 3000..."
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!

# Wait for either process to exit
wait $STUDIO_PID $CADDY_PID
