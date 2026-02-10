# Get Caddy binary from official image
FROM caddy:2.7-alpine AS caddy-source

FROM supabase/studio:20250113-83c9420

USER root

# Copy Caddy binary (avoids apk/apt dependency issues)
COPY --from=caddy-source /usr/bin/caddy /usr/bin/caddy

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENV HOSTNAME="0.0.0.0"
EXPOSE 3000

# Override base CMD to use Caddy auth proxy in front of Studio
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/sh", "/start.sh"]
