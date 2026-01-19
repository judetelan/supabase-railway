#!/bin/bash

# exit as soon as any of these commands fail, this prevents starting a database without certificates
set -e

# Fix permissions for Railway volume mount
# This runs as root before switching to postgres user
if [ "$(id -u)" = '0' ]; then
    echo "Running as root - setting up directory permissions..."

    # Create data directory with proper ownership
    mkdir -p /var/lib/postgresql/data
    chown -R postgres:postgres /var/lib/postgresql
    chmod 700 /var/lib/postgresql/data

    # Create custom config directory structure (as root for proper permissions)
    mkdir -p /var/lib/postgresql/data/custom/conf.d
    touch /var/lib/postgresql/data/custom/supautils.conf
    chown -R postgres:postgres /var/lib/postgresql/data/custom

    # Setup /etc/postgresql-custom symlink (must be done as root)
    rm -rf /etc/postgresql-custom 2>/dev/null || true
    ln -sf /var/lib/postgresql/data/custom /etc/postgresql-custom

    echo "Directory permissions set, config symlink created, restarting as postgres user..."
    exec gosu postgres "$0" "$@"
fi

# Make sure there is a PGDATA variable available
if [ -z "$PGDATA" ]; then
  echo "Missing PGDATA variable"
  exit 1
fi

# unset PGHOST to force psql to use Unix socket path
# this is specific to Railway and allows
# us to use PGHOST after the init
unset PGHOST

## unset PGPORT also specific to Railway
## since postgres checks for validity of
## the value in PGPORT we unset it in case
## it ends up being empty
unset PGPORT

# For some reason postgres doesn't want to respect our DBDATA variable. So we need to replace it
sed -i -e 's/data_directory = '\''\/var\/lib\/postgresql\/data'\''/data_directory = '\''\/var\/lib\/postgresql\/data\/pgdata'\''/g' /etc/postgresql/postgresql.conf

# Call the entrypoint script with the
# appropriate PGHOST & PGPORT and redirect
# the output to stdout if LOG_TO_STDOUT is true
if [[ "$LOG_TO_STDOUT" == "true" ]]; then
    /usr/local/bin/docker-entrypoint.sh "$@" 2>&1
else
    /usr/local/bin/docker-entrypoint.sh "$@"
fi
