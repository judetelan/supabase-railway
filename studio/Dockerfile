FROM supabase/studio:20250113-83c9420

USER root

# Install Caddy for basic auth proxy
RUN apk add --no-cache caddy

# Copy auth proxy config template and startup script
COPY Caddyfile.template /etc/caddy/Caddyfile.template
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

# Override base image entrypoint (docker-entrypoint.sh) so our start.sh runs
ENTRYPOINT []
CMD ["/bin/sh", "/start.sh"]
