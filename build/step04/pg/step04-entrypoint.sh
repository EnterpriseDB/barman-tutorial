#!/bin/bash

service ssh start

exec docker-entrypoint.sh "$@" &

tail -f /dev/null
