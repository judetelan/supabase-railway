FROM supabase/studio:20240729-ce42139

USER root

# Install Caddy for basic auth proxy
RUN apk add --no-cache caddy

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENV HOSTNAME="0.0.0.0"
EXPOSE 3000

# Override base CMD to use Caddy auth proxy in front of Studio
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/sh", "/start.sh"]
