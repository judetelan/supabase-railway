#!/bin/sh

echo "=== Studio Auth Proxy Starting ==="

# Set defaults for auth credentials
STUDIO_USER="${STUDIO_USERNAME:-admin}"
# Default password: 123456 (bcrypt cost 14)
STUDIO_HASH="${STUDIO_PASSWORD_HASH}"
if [ -z "$STUDIO_HASH" ]; then
    STUDIO_HASH='$2b$14$uWXyevN6Gn9fldzBLb.ty.SN4.aWp8blmrKeIosUvQaCji8rlft6q'
fi

echo "Auth user: $STUDIO_USER"

# Generate Caddyfile with auth credentials
# Health check paths bypass auth so Railway can verify the service is healthy
cat > /tmp/Caddyfile << CADDYEOF
{
    auto_https off
    admin off
}

:3000 {
    handle /api/profile {
        reverse_proxy localhost:3001
    }

    handle /api/platform/profile {
        reverse_proxy localhost:3001
    }

    handle {
        basicauth {
            ${STUDIO_USER} ${STUDIO_HASH}
        }
        reverse_proxy localhost:3001
    }
}
CADDYEOF

echo "Caddyfile generated."

# Start Caddy on port 3000 first (fast startup, handles health checks immediately)
caddy run --config /tmp/Caddyfile &
CADDY_PID=$!
echo "Caddy started (PID: $CADDY_PID)"

sleep 1

# Find the correct server.js path
if [ -f "/app/apps/studio/server.js" ]; then
    SERVER_PATH="/app/apps/studio/server.js"
elif [ -f "/app/server.js" ]; then
    SERVER_PATH="/app/server.js"
else
    SERVER_PATH=$(find /app -name "server.js" -path "*/studio/*" 2>/dev/null | head -1)
    if [ -z "$SERVER_PATH" ]; then
        SERVER_PATH=$(find /app -maxdepth 2 -name "server.js" 2>/dev/null | head -1)
    fi
fi

echo "Using server: $SERVER_PATH"

# Start Studio on internal port 3001
PORT=3001 node "$SERVER_PATH" &
STUDIO_PID=$!
echo "Studio started (PID: $STUDIO_PID)"

# Wait for Studio to be ready
for i in $(seq 1 60); do
    if wget -q --spider http://localhost:3001/api/profile 2>/dev/null; then
        echo "=== Studio Auth Proxy Ready ==="
        break
    fi
    sleep 1
done

# Wait for either process to exit
wait $CADDY_PID $STUDIO_PID
