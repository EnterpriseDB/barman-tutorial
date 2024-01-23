FROM ghcr.io/enterprisedb/barman-tutorial:step01-backup

RUN apt-get update \
    && apt-get -y install lsb-release cron sudo \
    && touch /var/log/cron.log\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN useradd --create-home --shell /bin/bash admin \
    && usermod -a -G sudo admin

RUN echo %sudo ALL = NOPASSWD : ALL >> /etc/sudoers

CMD cron && tail -f /var/log/cron.log

