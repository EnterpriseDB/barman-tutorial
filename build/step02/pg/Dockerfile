FROM shog9/barmantutorials:step01-pg

ADD step01.sh /docker-entrypoint-initdb.d/03-step01.sh

RUN apt-get update \
    && apt-get -y install barman-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*
