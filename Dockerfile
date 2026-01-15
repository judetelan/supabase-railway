FROM kong:2.8.1

# Install gettext for envsubst (Alpine uses apk)
USER root
RUN apk add --no-cache gettext bash

# Copy kong configuration template to home directory
COPY kong.yml /home/kong/kong.yml.template

# Set proper permissions for kong user
RUN chown -R kong:kong /home/kong

# Set Kong to run in DB-less mode with the declarative config
ENV KONG_DATABASE=off \
    KONG_DECLARATIVE_CONFIG=/home/kong/kong.yml \
    KONG_DNS_ORDER=LAST,A,CNAME \
    KONG_PLUGINS=request-transformer,cors,key-auth,acl,basic-auth,request-termination \
    KONG_NGINX_PROXY_PROXY_BUFFER_SIZE=160k \
    KONG_NGINX_PROXY_PROXY_BUFFERS=64\ 160k

# Expose ports
EXPOSE 8000 8443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD kong health || exit 1

# Use shell form to substitute env vars and start Kong
USER kong
CMD /bin/sh -c 'envsubst "\${SUPABASE_ANON_KEY} \${SUPABASE_SERVICE_KEY} \${DASHBOARD_USERNAME} \${DASHBOARD_PASSWORD}" < /home/kong/kong.yml.template > /home/kong/kong.yml && kong prepare -p /usr/local/kong && /usr/local/openresty/nginx/sbin/nginx -p /usr/local/kong -c nginx.conf -g "daemon off;"'
