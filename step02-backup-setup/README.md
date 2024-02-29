docker-compose up -d
docker exec -it -u admin backup /bin/bash

# Installing and Configuring Barman

In [the previous step](step01-db-setup), we configured the PostgreSQL server, creating users for Barman to connect and manage backups. In this step, we'll install and configure Barman on the backup server.

This demonstration uses an Ubuntu environment, so the first step is to configure the PostgreSQL repository ([details are on the PostgreSQL wiki](https://wiki.postgresql.org/wiki/Apt))

1. Install the postgresql-common package and other prerequesite software

    ```shell
    sudo apt update
    sudo apt install -y postgresql-common curl ca-certificates gnupg
    __OUTPUT__
    ...
    done.
    ```
2. Use the script included in postgresql-common to configure the PGDG repository

    ```shell
    sudo sh /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh 
    __OUTPUT__
    This script will enable the PostgreSQL APT repository on apt.postgresql.org on
    your system. The distribution codename used will be jammy-pgdg.

    Press Enter to continue, or Ctrl-C to abort.
    ...
    ```

   (Do press Enter at this point)

   ```output
   Reading package lists... Done

   You can now start installing packages from apt.postgresql.org.

   Have a look at https://wiki.postgresql.org/wiki/Apt for more information;
   most notably the FAQ at https://wiki.postgresql.org/wiki/Apt/FAQ
   ```


With the repository configured, we can use apt to install Barman and its dependencies:

```shell
sudo apt-get -y install barman
__OUTPUT__
...
Removing obsolete dictionary files:
Processing triggers for libc-bin (2.35-0ubuntu3.6) ...
```

For more details on installation (including instructions for other supported operating systems), see [the Installation section in the Barman guide](http://docs.pgbarman.org/release/3.10.0/#installation).

## Configuration

All the important details for a Barman server go into a server configuration file, by default located in `/etc/barman.d`. These are in the classic INI format, with relevant settings in a section named after the server we're going to back up. We'll also use that name for the configuration file itself. Since the server we intend to back up is named "pg", we'll use that:

```ini
cat <<'EOF' \
| sudo tee /etc/barman.d/pg.conf > /dev/null
[pg]
description =  "Example of PostgreSQL Database (Streaming-Only)"
conninfo = host=pg user=barman dbname=pagila
streaming_conninfo = host=pg user=streaming_barman dbname=pagila
backup_method = postgres
streaming_archiver = on
slot_name = barman
create_slot = auto
EOF
```

Note that this references the users (`barman` and `streaming_barman`) that we created [in step #1 - Database Server Configuration](step01-db-setup/). Also of interest is the value for `slot_name`: this is a replication slot that will also have to be created on the server, but we instruct Barman to do that for us by setting `create_slot` to `auto`.

The installation process created a brand-new barman user on the backup server, so let's switch to that for the rest of this:

```shell
sudo -i -u barman
__OUTPUT__
barman@backup:~$
```

### PostgreSQL Connection Password File

In order for Barman to connect via the user specified, we'll need to add the password we specified in the previous step to Barman's [.pgpass file](https://www.postgresql.org/docs/current/libpq-pgpass.html):

```shell
cat <<'EOF' >>~/.pgpass
pg:5432:*:barman:example-password
pg:5432:replication:streaming_barman:example-password
EOF
chmod 0600 ~/.pgpass
```

Each line in the `.pgpass` file need to follow below format:
```
[db_host]:[db_port]:[db_name]:[db_user]:[db_password]
```
Also note that the database name [db_name] for the barman streaming user MUST be `replication`

**Note the change in permissions** - this is necessary to protect the visibility of the file, and PostgreSQL will not use it unless permissions are restricted.

!!! Tip Further reading
For more details on configuration files, see: [Configuration](http://docs.pgbarman.org/release/3.10.0/#configuration) in the pgBarman guide.
!!!

### Verifying the configuration

During installation, Barman will have installed a cron service that runs every minute to maintenance tasks. Since we only just gave it a configuration, let's make sure those tasks have run before continuing: 

```shell
barman cron
__OUTPUT__
Starting WAL archiving for server pg
Starting streaming archiver for server pg
```

Now that the configuration is done and initialization has been performed, we can use Barman's check command to verify that it works:

```shell
barman check pg
__OUTPUT__
Server pg:
        WAL archive: FAILED (please make sure WAL shipping is setup)
        PostgreSQL: OK
        superuser or standard user with backup privileges: OK
        PostgreSQL streaming: OK
        wal_level: OK
        replication slot: OK
        directories: OK
        retention policy settings: OK
        backup maximum age: OK (no last_backup_maximum_age provided)
        compression settings: OK
        failed backups: OK (there are 0 failed backups)
        minimum redundancy requirements: OK (have 0 backups, expected at least 0)
        pg_basebackup: OK
        pg_basebackup compatible: OK
        pg_basebackup supports tablespaces mapping: OK
        systemid coherence: OK (no system Id stored on disk)
        pg_receivexlog: OK
        pg_receivexlog compatible: OK
        receive-wal running: OK
        archiver errors: OK
```

Uh-oh! WAL archive failed? Not a problem - that just means Barman hasn't seen any new WAL archives come in yet, which isn't surprising given this is an example 
database with no writes happening! We can trigger an archive manually and verify that this works:

```shell
barman switch-wal --archive --archive-timeout 60 pg
__OUTPUT__
The WAL file 000000010000000000000002 has been closed on server 'pg'
Waiting for the WAL file 000000010000000000000002 from server 'pg' (max: 60 seconds)
Processing xlog segments from streaming for pg
        000000010000000000000002
```
This forces WAL rotation and (with the `--archive` option) waits for the WAL to arrive. We'll give it 60 seconds (with the `--archive-timeout` option) to complete; 
if it doesn't complete within that amount of time, try again. For more detail on these commands and their options, refer to [the Barman man page](https://docs.pgbarman.org/release/3.10.0/barman.1.html#commands).

Once switch-wal has completed successfully, run the check again and you should see all checks passing:

```shell
barman check pg
__OUTPUT__
Server pg:
        PostgreSQL: OK
        superuser or standard user with backup privileges: OK
        PostgreSQL streaming: OK
        wal_level: OK
        replication slot: OK
        directories: OK
        retention policy settings: OK
        backup maximum age: OK (no last_backup_maximum_age provided)
        compression settings: OK
        failed backups: OK (there are 0 failed backups)
        minimum redundancy requirements: OK (have 0 backups, expected at least 0)
        pg_basebackup: OK
        pg_basebackup compatible: OK
        pg_basebackup supports tablespaces mapping: OK
        systemid coherence: OK (no system Id stored on disk)
        pg_receivexlog: OK
        pg_receivexlog compatible: OK
        receive-wal running: OK
        archiver errors: OK
```


Continue on with [Step #3: Running Backups](../step03-backup/README.md).
