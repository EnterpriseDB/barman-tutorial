#!/bin/bash

service cron start
service ssh start

# get pg reasonably close to the state it was in at the end of step #2
su - barman -c "
while ! pg_isready -h pg 
  do sleep 2
done
# increment WAL on server
/usr/bin/barman switch-wal --force pg
# create slot
/usr/bin/barman receive-wal --create-slot pg
# restore the archived server state
rm -rf /var/lib/barman/pg
tar xvf /var/lib/barman/pg.tar.gz -C /var/lib/barman/
rm /var/lib/barman/pg.tar.gz
# kickstart services
/usr/bin/barman cron
"

exec "$@"
