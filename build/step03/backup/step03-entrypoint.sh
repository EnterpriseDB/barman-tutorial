#!/bin/bash

service cron start
service ssh start

# restore the archived server state
rm -rf /var/lib/barman/pg
tar xvf /var/lib/barman/pg.tar.gz -C /var/lib/barman/

# get pg reasonably close to the state it was in at the end of step #2
su - barman -c "
while ! pg_isready -h pg 
  do sleep 2
done
barman receive-wal --create-slot pg
barman cron
barman switch-wal --force pg
"

exec "$@"
