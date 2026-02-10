FROM supabase/studio:20240729-ce42139

USER root
RUN apk add --no-cache caddy

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENV HOSTNAME="0.0.0.0"
EXPOSE 3000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/sh", "/start.sh"]
