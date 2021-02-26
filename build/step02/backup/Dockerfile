FROM ubuntu:focal

RUN apt-get update \
    && apt-get -y install lsb-release cron \
    && touch /var/log/cron.log

CMD cron && tail -f /var/log/cron.log

