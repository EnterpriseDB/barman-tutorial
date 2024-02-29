docker-compose up -d
docker exec -it -u postgres pg /bin/bash

## Database Server Configuration

For Barman to back up this server, a few things need to be done to prepare it:

1. Installing the Barman CLI tools
2. Creating a dedicated superuser for Barman to connect as
3. Creating a dedicated streaming user with the replication attribute and remote login permissions
4. Ensuring there are free replication slots

### Barman CLI installation

We'll start by installing the barman-cli package: this contains the `barman-wal-archive` and `barman-wal-restore` commands that will be used to transmit data to and from our backup server.

Since PostgreSQL is already installed, the PostgreSQL apt repository is already configured and we can just request the package:

```shell
sudo apt-get update
sudo apt-get -y install barman-cli
__OUTPUT__
...
Setting up barman-cli (3.9.0-1.pgdg120+1) ...
Setting up python3-importlib-metadata (4.12.0-1) ...
Setting up python3-botocore (1.29.27+repack-1) ...
Setting up python3-s3transfer (0.6.0-1) ...
Setting up python3-boto3 (1.26.27+dfsg-1) ...
Setting up barman-cli-cloud (3.9.0-1.pgdg120+1) ...
Processing triggers for systemd (252.19-1~deb12u1) ...
Processing triggers for ca-certificates (20230311) ...
Updating certificates in /etc/ssl/certs...
0 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

### User provisioning

Let's call our dedicated backup user, "barman". We'll create it interactively via the [`createuser`](https://www.postgresql.org/docs/current/app-createuser.html) utility:

```shell
createuser --superuser -P barman
__OUTPUT__
Enter password for new role: 
Enter it again: 
```

Enter `example-password` when prompted (twice).

!!! Note Make note of that password
    We'll need to add it to the ~/.pgpass file on the backup server later!

We're making this a superuser account, which will allow it full control of all databases on this server. **Be very careful** with superuser credentials! Anyone who can connect as a superuser account owns your data.

Now we will create the streaming replication user, "streaming_barman". This doesn't need to be a superuser, but it does need the replication attribute:

```shell
createuser --replication -P streaming_barman
__OUTPUT__
Enter password for new role: 
Enter it again: 
```

Enter `example-password` when prompted (twice).

We'll also need to edit `pg_hba.conf` to allow the barman user to connect from the backup server, and also to allow the streaming user to [connect in replication mode](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html).

```shell
sed -i '$ a host all         barman           all scram-sha-256' /var/lib/postgresql/data/pg_hba.conf
sed -i '$ a host replication streaming_barman all scram-sha-256' /var/lib/postgresql/data/pg_hba.conf
cat /var/lib/postgresql/data/pg_hba.conf
__OUTPUT__
...
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust

host all all all scram-sha-256
host all         barman           all scram-sha-256
host replication streaming_barman all scram-sha-256
```

!!! Note
The pg_hba.conf configuration in this demonstration contains a catch-all entry that allows any user to connect to any database from any host; strictly-speaking, this makes adding an entry for our `barman` user unnecessary, but we'll add it anyway just to be thorough.
!!!

For these changes to take effect, we need to signal to PostgreSQL that it needs to reload its configuration files:

```shell
pg_ctl reload
__OUTPUT__
server signaled
```

### Enable remote access to your PostgreSQL Server

If the PostgreSQL server isn't already configured for remote access, or is restricted to connections from known machines, our database server won't be able to connect.

We'll use psql to check this setting:

```shell
psql -d pagila
```

The relevant configuration parameter is [`listen_addresses`](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-LISTEN-ADDRESSES):

```sql
show listen_addresses;
__OUTPUT__
 listen_addresses 
------------------
 *
(1 row)
```

The value for this server is `*` - which allows connections from anything. This doesn't need to be changed. If the value were to be empty, `localhost`, or a list of hosts or addresses that don't include our database server, we'd need to add its hostname (`backup`) to the list, or change it to the wildcard. 

```sql
ALTER SYSTEM SET listen_addresses TO "*";
__OUTPUT__
ALTER SYSTEM
```

!!! Note
If you change this setting, you'll need to restart the database server for it to take effect. Since our setting was already allowing all remote connections, we don't need to do that.
!!!

### Database settings for streaming

We'll also need to make sure there are replication slots available, and that PostgreSQL will allow another sender to connect. We'll continue to use psql to check the current settings:

```sql
Show max_wal_senders;
Show max_replication_slots;
__OUTPUT__
 max_wal_senders
-----------------
 10
(1 row)

 max_replication_slots
-----------------------
 10
(1 row)
```

The default for both of these (for PostgreSQL 10 and above) is 10, so we're fine - but if we needed more (or if they'd been previously set to 0, thus [disabling replication](https://www.postgresql.org/docs/current/runtime-config-replication.html)) then we'd need to increase them. You could do this by using the commands `ALTER SYSTEM SET max_wal_senders = 10;` and `ALTER SYSTEM SET max_replication_slots = 10;`. 

!!! Note
If you change these settings, you'll need to restart the database server for them to take effect. Since our settings were already correct, we don't need to restart.
!!!

### Gazing fondly at data

As we mentioned at the start, the server is preloaded with [the Pagila database](https://github.com/devrimgunduz/pagila). This is a schema designed for examples  and includes, among other things, information about actors. Before we end this step, let's query some of that data - this is what we're going to back up!

```sql
select * from actor where last_name='KILMER';
\q
__OUTPUT__
 actor_id | first_name | last_name |      last_update       
----------+------------+-----------+------------------------
       23 | SANDRA     | KILMER    | 2020-02-15 09:34:33+00
       45 | REESE      | KILMER    | 2020-02-15 09:34:33+00
       55 | FAY        | KILMER    | 2020-02-15 09:34:33+00
      153 | MINNIE     | KILMER    | 2020-02-15 09:34:33+00
      162 | OPRAH      | KILMER    | 2020-02-15 09:34:33+00
(5 rows)
```

We'll verify later on that this can be restored reliably.

Continue on with [Step #2: Backup Server Configuration](step02-backup-setup).
