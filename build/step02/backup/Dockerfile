FROM ghcr.io/enterprisedb/barman-tutorial:step01-backup

RUN apt-get update \
    && apt-get -y install lsb-release cron \
    && touch /var/log/cron.log\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

CMD cron && tail -f /var/log/cron.log
