FROM postgres:13

ENV POSTGRES_DB=pagila
ADD --chown=postgres https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-schema.sql /docker-entrypoint-initdb.d/01-pagila-schema.sql
ADD --chown=postgres https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-data.sql /docker-entrypoint-initdb.d/02-pagila-data.sql

# suppress interactive prompt for timezone when installing
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# fake init / runlevel so that services start properly after install
RUN echo exit 0 > /usr/sbin/policy-rc.d
ENV RUNLEVEL=1

COPY --chown=postgres .ssh /var/lib/postgresql/.ssh
RUN chmod 0700 /var/lib/postgresql/.ssh
RUN chmod 0600 /var/lib/postgresql/.ssh/id_rsa /var/lib/postgresql/.ssh/authorized_keys

# allow sudo for installation purposes
RUN apt-get update \
    && apt-get -y install sudo rsync ssh openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*
RUN usermod -a -G sudo postgres \
    && echo '%sudo ALL=NOPASSWD:ALL' >> /etc/sudoers

ADD step01-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/step01-entrypoint.sh
ENTRYPOINT ["step01-entrypoint.sh"]
CMD ["postgres"]
