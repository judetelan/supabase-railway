FROM supabase/studio:20250113-83c9420

USER root

# Install Caddy for basic auth proxy
RUN apk add --no-cache caddy

# Copy auth proxy config
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Required environment variables for Studio
ENV HOSTNAME="0.0.0.0"
ENV DEFAULT_ORGANIZATION_NAME="Default Organization"
ENV DEFAULT_PROJECT_NAME="Default Project"

# These MUST be set via Railway environment variables:
# STUDIO_USERNAME       - Basic auth username (default: admin)
# STUDIO_PASSWORD_HASH  - Bcrypt hash from: caddy hash-password --plaintext 'yourpassword'
# STUDIO_PG_META_URL    - URL to Meta service
# SUPABASE_URL          - Gateway URL (NOT PostgREST!)
# SUPABASE_PUBLIC_URL   - Gateway URL (NOT PostgREST!)
# SUPABASE_ANON_KEY     - Anonymous key
# SUPABASE_SERVICE_KEY  - Service role key
# AUTH_JWT_SECRET        - JWT secret
# POSTGRES_PASSWORD      - Database password

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/platform/profile || exit 1

CMD ["/start.sh"]
