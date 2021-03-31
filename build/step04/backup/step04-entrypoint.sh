#!/bin/bash

service cron start
service ssh start

# do NOT try to actually get barman replication working against 
# the (uninitialized) pg server here!
su - barman -c "
while ! pg_isready -h pg 
  do sleep 2
done
# just restore the archived server state
rm -rf /var/lib/barman/pg
tar xvf /var/lib/barman/pg.tar.gz -C /var/lib/barman/
rm /var/lib/barman/pg.tar.gz
"

exec "$@"
