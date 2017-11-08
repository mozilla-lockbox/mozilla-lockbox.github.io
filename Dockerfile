FROM jekyll/jekyll

VOLUME ["/srv/jekyll"]
EXPOSE 4000

WORKDIR "/srv/jekyll"

COPY _utils/dev_config.yml /srv/dev_config.yml
COPY _utils/startup.sh /srv/startup.sh

ENTRYPOINT ["/srv/startup.sh"]
CMD ["jekyll", "serve", "--watch", "--config", "_config.yml,/srv/dev_config.yml"]
