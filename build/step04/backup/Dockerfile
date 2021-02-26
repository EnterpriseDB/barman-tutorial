FROM ubuntu:focal

RUN apt-get update \
    && apt-get -y install lsb-release cron \
        curl ca-certificates gnupg \
        ssh \
    && touch /var/log/cron.log 

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN apt-get update \
    && apt-get -y install barman \
    && apt-get clean 

COPY pg.conf /etc/barman.d/pg.conf
COPY --chown=barman barman/.pgpass /var/lib/barman/
COPY --chown=barman barman/.ssh /var/lib/barman/.ssh
COPY --chown=barman barman/pg /var/lib/barman/pg
RUN chmod 0600 /var/lib/barman/.pgpass
RUN chmod 0700 /var/lib/barman/.ssh
RUN chmod 0600 /var/lib/barman/.ssh/id_rsa

CMD cron && tail -f /var/log/cron.log
