#!/bin/bash
# temp; this should be a github action

docker login ghcr.io

docker push ghcr.io/enterprisedb/barman-tutorial:step01-backup
docker push ghcr.io/enterprisedb/barman-tutorial:step02-backup
docker push ghcr.io/enterprisedb/barman-tutorial:step03-backup
docker push ghcr.io/enterprisedb/barman-tutorial:step04-backup
docker push ghcr.io/enterprisedb/barman-tutorial:step01-pg
docker push ghcr.io/enterprisedb/barman-tutorial:step02-pg
docker push ghcr.io/enterprisedb/barman-tutorial:step03-pg
docker push ghcr.io/enterprisedb/barman-tutorial:step04-pg
