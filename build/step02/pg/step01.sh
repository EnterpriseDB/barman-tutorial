#!/bin/bash
# This establishes the baseline that should exist if the instructions in step01 were followed

psql pagila -c "\
Create Role barman \
    Login Superuser \
    Password 'example-password'; \
Create Role streaming_barman \
    Login Replication \
    Password 'example-password'; \
"

sed -i '$ a host all         barman           all scram-sha-256' /var/lib/postgresql/data/pg_hba.conf
sed -i '$ a host replication streaming_barman all scram-sha-256' /var/lib/postgresql/data/pg_hba.conf
