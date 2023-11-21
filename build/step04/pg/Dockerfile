FROM shog9/barmantutorials:step03-pg

# Fake destruction of the database... by never initializing it
RUN rm /docker-entrypoint-initdb.d/01-pagila-schema.sql /docker-entrypoint-initdb.d/02-pagila-data.sql
