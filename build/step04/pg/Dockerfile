FROM postgres:13

ENV POSTGRES_DB=pagila

RUN apt-get update \
    && apt-get -y install ssh openssh-server rsync \
    && mkdir /run/sshd

COPY --chown=postgres .ssh /var/lib/postgresql/.ssh
RUN chmod 0700 /var/lib/postgresql/.ssh
RUN chmod 0600 /var/lib/postgresql/.ssh/authorized_keys

ADD step01.sh /docker-entrypoint-initdb.d/03-step01.sh
ADD step04-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/step04-entrypoint.sh
ENTRYPOINT ["step04-entrypoint.sh"]
CMD ["postgres"]