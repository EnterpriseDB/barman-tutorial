FROM postgres:13

ENV POSTGRES_DB=pagila

ADD --chown=postgres https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-schema.sql /docker-entrypoint-initdb.d/01-pagila-schema.sql
ADD --chown=postgres https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-data.sql /docker-entrypoint-initdb.d/02-pagila-data.sql
ADD step01.sh /docker-entrypoint-initdb.d/03-step01.sh

