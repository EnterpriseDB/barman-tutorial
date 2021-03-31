#!/bin/bash

service ssh start

# want to be able to shut down and restart the database
# WITHOUT killing the container (that's part of the demo)
# so don't allow this to be "the" docker process
# but still capture the output for debugging purposes
exec docker-entrypoint.sh "$@" & > /var/log/postgresql/pg.log
chown postgres:postgres /var/log/postgresql/pg.log
cat /var/log/postgresql/pg.log

# faster / cleaner shutdown while testing
kill_postgres()
{
  kill -SIGINT $(pgrep -o postgres)
}
trap kill_postgres SIGINT

# keep reading from the file
tail -f -n 0 /var/log/postgresql/pg.log &
wait $!
