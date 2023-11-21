#!/bin/bash
# temp; this should be a github action

docker login -u shog9

docker push shog9/barmantutorials:step01-backup
docker push shog9/barmantutorials:step02-backup
docker push shog9/barmantutorials:step03-backup
docker push shog9/barmantutorials:step04-backup
docker push shog9/barmantutorials:step01-pg
docker push shog9/barmantutorials:step02-pg
docker push shog9/barmantutorials:step03-pg
docker push shog9/barmantutorials:step04-pg
