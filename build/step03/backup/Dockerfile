FROM ubuntu:focal

RUN apt-get update \
    && apt-get -y install lsb-release cron \
        curl ca-certificates gnupg \
    && touch /var/log/cron.log

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN apt-get update \
    && apt-get -y install barman \
    && apt-get clean 

COPY pg.conf /etc/barman.d/pg.conf
COPY --chown=barman barman/.pgpass /var/lib/barman/
COPY --chown=barman barman/pg /var/lib/barman/pg
RUN chmod 0600 /var/lib/barman/.pgpass

CMD cron \
    && su - barman -c "barman receive-wal --create-slot pg; barman cron" \
    && tail -f /var/log/cron.log
