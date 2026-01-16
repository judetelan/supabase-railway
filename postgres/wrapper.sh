#!/bin/bash
set -e

# Ensure PGDATA is set
if [ -z "$PGDATA" ]; then
    export PGDATA=/var/lib/postgresql/data
fi

# Unset PGHOST and PGPORT to force Unix socket connection during initialization
unset PGHOST
unset PGPORT

# Create data directory structure if needed
if [ ! -d "$PGDATA/pgdata" ]; then
    mkdir -p "$PGDATA/pgdata"
    chown -R postgres:postgres "$PGDATA"
fi

# Update postgresql.conf data_directory if it exists
if [ -f "/etc/postgresql/postgresql.conf" ]; then
    sed -i "s|data_directory = '.*'|data_directory = '/var/lib/postgresql/data/pgdata'|" /etc/postgresql/postgresql.conf
fi

# Create custom config directory if needed
CUSTOM_CONFIG_DIR="/var/lib/postgresql/data/custom"
if [ ! -d "$CUSTOM_CONFIG_DIR" ]; then
    mkdir -p "$CUSTOM_CONFIG_DIR"
    chown postgres:postgres "$CUSTOM_CONFIG_DIR"
fi

# Create symlink for custom config if it doesn't exist
if [ ! -L "/etc/postgresql-custom" ] && [ ! -d "/etc/postgresql-custom" ]; then
    ln -s "$CUSTOM_CONFIG_DIR" /etc/postgresql-custom 2>/dev/null || true
fi

# Run the docker entrypoint
if [ "$LOG_TO_STDOUT" = "true" ]; then
    exec /docker-entrypoint.sh "$@" 2>&1
else
    exec /docker-entrypoint.sh "$@"
fi
