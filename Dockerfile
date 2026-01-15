FROM kong:2.8.1

# Install gettext for envsubst (Alpine uses apk)
USER root
RUN apk add --no-cache gettext

# Copy kong configuration template and entrypoint
COPY kong.yml /var/lib/kong/kong.yml.template
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set Kong to run in DB-less mode with the declarative config
ENV KONG_DATABASE=off \
    KONG_DECLARATIVE_CONFIG=/var/lib/kong/kong.yml \
    KONG_DNS_ORDER=LAST,A,CNAME \
    KONG_PLUGINS=request-transformer,cors,key-auth,acl,basic-auth,request-termination \
    KONG_NGINX_PROXY_PROXY_BUFFER_SIZE=160k \
    KONG_NGINX_PROXY_PROXY_BUFFERS=64\ 160k

# Expose ports
EXPOSE 8000 8443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD kong health || exit 1

# Use our custom entrypoint
USER kong
ENTRYPOINT ["/docker-entrypoint.sh"]
