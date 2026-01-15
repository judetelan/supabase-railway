FROM kong:2.8.1

# Install gettext for envsubst (Alpine uses apk)
USER root
RUN apk add --no-cache gettext bash

# Copy kong configuration template to home directory
COPY kong.yml /home/kong/kong.yml.template

# Set proper permissions for kong user
RUN chown -R kong:kong /home/kong

# Set Kong to run in DB-less mode with the declarative config
# PORT env var is injected by Railway at runtime
ENV KONG_DATABASE=off \
    KONG_DECLARATIVE_CONFIG=/home/kong/kong.yml \
    KONG_DNS_ORDER=LAST,A,CNAME \
    KONG_PLUGINS=request-transformer,cors,key-auth,acl,basic-auth,request-termination \
    KONG_NGINX_PROXY_PROXY_BUFFER_SIZE=160k \
    KONG_NGINX_PROXY_PROXY_BUFFERS=64\ 160k \
    KONG_NGINX_DAEMON=off \
    PORT=8000

# Expose ports
EXPOSE 8000 8443

# Use shell form to substitute env vars and start Kong
# No HEALTHCHECK - let Railway handle it
USER kong
CMD /bin/sh -c 'echo "PORT is: ${PORT}" && export KONG_PROXY_LISTEN="0.0.0.0:${PORT:-8000}" && echo "KONG_PROXY_LISTEN is: $KONG_PROXY_LISTEN" && envsubst "\${SUPABASE_ANON_KEY} \${SUPABASE_SERVICE_KEY} \${DASHBOARD_USERNAME} \${DASHBOARD_PASSWORD}" < /home/kong/kong.yml.template > /home/kong/kong.yml && kong prepare -p /usr/local/kong && echo "Starting nginx..." && /usr/local/openresty/nginx/sbin/nginx -p /usr/local/kong -c nginx.conf'
