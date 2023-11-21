#!/bin/bash

docker build --pull -t shog9/barmantutorials:step01-backup build/step01/backup/
docker build -t shog9/barmantutorials:step02-backup build/step02/backup/
docker build -t shog9/barmantutorials:step03-backup build/step03/backup/
docker build -t shog9/barmantutorials:step04-backup build/step04/backup/
docker build --pull -t shog9/barmantutorials:step01-pg build/step01/pg/
docker build -t shog9/barmantutorials:step02-pg build/step02/pg/
docker build -t shog9/barmantutorials:step03-pg build/step03/pg/
docker build -t shog9/barmantutorials:step04-pg build/step04/pg/
