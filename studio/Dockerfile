FROM supabase/studio:20250113-83c9420

USER root

# Install Caddy for basic auth proxy
RUN apk add --no-cache caddy

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Required environment variables
ENV HOSTNAME="0.0.0.0"
ENV DEFAULT_ORGANIZATION_NAME="Default Organization"
ENV DEFAULT_PROJECT_NAME="Default Project"

EXPOSE 3000
