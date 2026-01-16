#!/bin/bash
set -e

# Start postgres in background
/docker-entrypoint.sh postgres &

# Wait for postgres to be ready
echo "Waiting for PostgreSQL to start..."
until pg_isready -h localhost -p 5432 -U postgres; do
    sleep 2
done

echo "PostgreSQL is ready, running migration..."

# Run the role setup SQL
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h localhost -U "${POSTGRES_USER:-supabase_admin}" -d "${POSTGRES_DB:-postgres}" -f /docker-entrypoint-initdb.d/99-setup-roles.sql || echo "Migration may have already run"

echo "Migration complete, postgres is running..."

# Wait for postgres background process
wait
