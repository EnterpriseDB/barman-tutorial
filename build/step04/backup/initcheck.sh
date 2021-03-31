#!/bin/bash

# it's (just barely) possible to start running the scenario before 
# the container is fully initialized (backups restored, etc) 
# check for this and provide a helpful message, or forward on to real barman
if test -f "/var/lib/barman/pg.tar.gz"
then
  echo "still initializing, try again!"
else
  exec /usr/bin/barman "$@"
fi