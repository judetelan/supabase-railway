FROM supabase/postgres:15.8.1.085

# Copy initialization scripts
COPY realtime.sql /docker-entrypoint-initdb.d/migrations/99-realtime.sql
COPY webhooks.sql /docker-entrypoint-initdb.d/migrations/99-webhooks.sql
COPY roles.sql /docker-entrypoint-initdb.d/init-scripts/99-roles.sql
COPY jwt.sql /docker-entrypoint-initdb.d/init-scripts/99-jwt.sql
COPY _supabase.sql /docker-entrypoint-initdb.d/migrations/97-supabase.sql
COPY logs.sql /docker-entrypoint-initdb.d/migrations/98-logs.sql
COPY pooler.sql /docker-entrypoint-initdb.d/migrations/99-pooler.sql

# Copy wrapper script
COPY --chmod=755 wrapper.sh /usr/local/bin/wrapper.sh

ENTRYPOINT ["wrapper.sh"]
CMD ["postgres", "-D", "/var/lib/postgresql/data"]
