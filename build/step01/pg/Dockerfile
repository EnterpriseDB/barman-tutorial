FROM postgres:13

ENV POSTGRES_DB=pagila
# TODO: just build the database and copy it in (only if volume not needed)
ADD --chown=postgres https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-schema.sql /docker-entrypoint-initdb.d/01-pagila-schema.sql
ADD --chown=postgres https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-data.sql /docker-entrypoint-initdb.d/02-pagila-data.sql

