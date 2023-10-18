#!/bin/bash

set -x

REPO=EnterpriseDB/barman-tutorial
TAG="ghcr.io/${REPO,,}"
LABEL1="org.opencontainers.image.source=https://github.com/$REPO"
LABEL2="org.opencontainers.image.description=Barman tutorial scenario"
LABEL3="org.opencontainers.image.licenses=Apache-2.0"

docker build --label "$LABEL1" --label "$LABEL2" --label "$LABEL3" --pull -t $TAG:step01-backup build/step01/backup
docker build --label "$LABEL1" --label "$LABEL2" --label "$LABEL3" -t $TAG:step02-backup build/step02/backup
docker build --label "$LABEL1" --label "$LABEL2" --label "$LABEL3" -t $TAG:step03-backup build/step03/backup
docker build --label "$LABEL1" --label "$LABEL2" --label "$LABEL3" -t $TAG:step04-backup build/step04/backup
docker build --label "$LABEL1" --label "$LABEL2" --label "$LABEL3" --pull -t $TAG:step01-pg build/step01/pg
docker build --label "$LABEL1" --label "$LABEL2" --label "$LABEL3" -t $TAG:step02-pg build/step02/pg
docker build --label "$LABEL1" --label "$LABEL2" --label "$LABEL3" -t $TAG:step03-pg build/step03/pg
docker build --label "$LABEL1" --label "$LABEL2" --label "$LABEL3" -t $TAG:step04-pg build/step04/pg

