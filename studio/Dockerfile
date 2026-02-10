FROM supabase/studio:20250113-83c9420

USER root

# Install Caddy for basic auth proxy
RUN apk add --no-cache caddy

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Required environment variables for Studio
ENV HOSTNAME="0.0.0.0"
ENV DEFAULT_ORGANIZATION_NAME="Default Organization"
ENV DEFAULT_PROJECT_NAME="Default Project"

# These MUST be set via Railway environment variables:
# STUDIO_USERNAME       - Basic auth username (default: admin)
# STUDIO_PASSWORD_HASH  - Bcrypt hash (default: 123456)
# STUDIO_PG_META_URL    - URL to Meta service
# SUPABASE_URL          - Gateway URL (NOT PostgREST!)
# SUPABASE_PUBLIC_URL   - Gateway URL (NOT PostgREST!)
# SUPABASE_ANON_KEY     - Anonymous key
# SUPABASE_SERVICE_KEY  - Service role key

EXPOSE 3000

# Keep base entrypoint for env var loading, override CMD to our script
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/sh", "/start.sh"]
