#!/bin/bash
# This establishes the baseline that should exist if the instructions in step01 were followed

psql pagila -c "\
Create Role barman \
    Login Superuser Replication \
    Password 'example-password'; \
Create Role streaming_barman \
    Login Replication \
    Password 'example-password'; \
"

sed -i '$ a host   replication    streaming_barman   all md5' /var/lib/postgresql/data/pg_hba.conf
