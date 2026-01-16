#!/bin/bash
set -e

# Ensure PGDATA is set to subdirectory
export PGDATA=/var/lib/postgresql/data/pgdata

# Remove any stale files from volume root that might confuse the init
# Only remove if pgdata subdirectory doesn't have valid data
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Cleaning up stale data..."
    # Remove old postgres files from volume root (but not the pgdata subdir)
    find /var/lib/postgresql/data -maxdepth 1 -type f -delete 2>/dev/null || true
    # Make sure pgdata directory exists
    mkdir -p "$PGDATA"
    chown postgres:postgres "$PGDATA"
fi

# Run the original entrypoint
exec /docker-entrypoint.sh "$@"
