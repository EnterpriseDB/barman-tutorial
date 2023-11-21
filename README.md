# Barman Single-Server Streaming Configuration

This tutorial provides a quick walk-through of setting up a backup and recovery scenario using a Barman server and a PostgreSQL server. It covers:

1. Configuring the database server to allow Barman to collect data via streaming replication
2. Installing Barman on an Ubuntu system
3. Configuring Barman for streaming replication
4. Validating a Barman configuration
5. Running a full backup
6. Restoring a full backup

## Running these scenarios

### Step 01: Database Server Configuration

1. Run: 

    ```shell
    docker-compose -f step01-db-setup/docker-compose.yaml up -d
    docker exec -it -u postgres pg /bin/bash
    ```

2. Follow the instructions in [step01-db-setup/README.md](step01-db-setup/README.md)

3. Run:

    ```shell
    docker-compose -f step01-db-setup/docker-compose.yaml down
    ```

    ...to clean up the containers before starting the next step.

### Step 02: Installing and Configuring Barman

1. Run: 

    ```shell
    docker-compose -f step02-backup-setup/docker-compose.yaml up -d
    docker exec -it backup /bin/bash
    ```

2. Follow the instructions in [step02-backup-setup/README.md](step02-backup-setup/README.md)

3. Run:

    ```shell
    docker-compose -f step02-backup-setup/docker-compose.yaml down
    ```

    ...to clean up the containers before starting the next step.

### Step 03: Running Backups With Barman

1. Run: 

    ```shell
    docker-compose -f step03-backup/docker-compose.yaml up -d
    docker exec -it -u barman backup /bin/bash
    ```

2. Follow the instructions in [step03-backup/README.md](step03-backup/README.md)

3. Run:

    ```shell
    docker-compose -f step03-backup/docker-compose.yaml down
    ```

    ...to clean up the containers before starting the next step.

### Step 04: Restoring a Backup With Barman

1. Run: 

    ```shell
    docker-compose -f step04-restore/docker-compose.yaml up -d
    docker exec -it -u barman backup /bin/bash
    ```

2. Follow the instructions in [step04-restore/README.md](step04-restore/README.md)

3. Run:

    ```shell
    docker-compose -f step04-restore/docker-compose.yaml down
    ```

    ...to clean up the containers.
    
## Building the images

The build system is quite simplistic: two scripts under ./build 

1. `build/build-images.sh` will build and tag the 8 images used by the Compose files under step01-step04. Changes can then be tested locally.
2. `build/push-images.sh` will push these images up to Github. 

Normally you shouldn't have to run the push script - once you've built and verified the images locally, check in and push your changes and Github Actions will rebuild and push the new images.

If changes are made to the scenario steps that affect the intermediate backups in steps #2 or #3, you'll need to create new archives of the `pg` backup directory at the conclusion of BOTH steps #2 and #3. 

```shell
# from within container
tar cvfz pg.tar.gz -C ~ pg
```

Then copy that archive into the build directory for the next steps (`build/step03/backup/barman` and `build/step04/backup/barman` respectively).

```shell
# from host (after step #2 but before cleanup)
docker cp backup:/var/lib/barman/pg.tar.gz build/step03/backup/barman
```