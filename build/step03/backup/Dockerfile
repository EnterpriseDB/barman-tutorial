FROM ghcr.io/enterprisedb/barman-tutorial:step02-backup

ADD https://www.postgresql.org/media/keys/ACCC4CF8.asc /usr/share/keyrings/pgdg-archive-keyring

RUN apt-get update \
    && apt-get -y install postgresql-common curl ca-certificates gnupg ssh openssh-server \
    && echo | /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh \
    && apt-get update \
    && apt-get -y install barman \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

COPY pg.conf /etc/barman.d/pg.conf
COPY --chown=barman barman/.pgpass /var/lib/barman/
RUN chmod 0600 /var/lib/barman/.pgpass

COPY --chown=barman barman/pg.tar.gz /var/lib/barman/
COPY --chown=barman .ssh /var/lib/barman/.ssh
RUN chmod 0700 /var/lib/barman/.ssh
RUN chmod 0600 /var/lib/barman/.ssh/id_rsa /var/lib/barman/.ssh/authorized_keys

# don't allow running barman until entrypoint script has completed initialization
COPY initcheck-barman.sh /usr/local/bin/barman
RUN chmod +x /usr/local/bin/barman

COPY step03-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/step03-entrypoint.sh

RUN usermod -a -G sudo barman 

ENTRYPOINT ["step03-entrypoint.sh"]
CMD tail -f /var/log/cron.log
