docker-compose up -d
docker exec -it -u barman backup /bin/bash

# Running Backups With Barman

With [the Barman server configured in our last step](step02-backup-setup), we can run a full backup (or "base backup").

To run a full backup, we use [Barman's `backup` command](http://docs.pgbarman.org/release/3.9.0/#backup):

```shell
barman backup pg --wait
__OUTPUT__
Starting backup using postgres method for server pg in /var/lib/barman/pg/base/20240117T052502
Backup start at LSN: 0/30AA960 (000000010000000000000003, 000AA960)
Starting backup copy via pg_basebackup for 20240117T052502
Copy done (time: 18 seconds)
Finalising the backup.
This is the first backup for server pg
WAL segments preceding the current backup have been found:
        000000010000000000000002 from server pg has been removed
Backup size: 38.1 MiB
Backup end at LSN: 0/5000000 (000000010000000000000004, 00000000)
Backup completed (start time: 2024-01-17 05:25:02.461358, elapsed time: 19 seconds)
Waiting for the WAL file 000000010000000000000004 from server 'pg'
Processing xlog segments from streaming for pg
        000000010000000000000003
        000000010000000000000004
```

The `--wait` option causes Barman to wait for arrival and processing of the WAL file corresponding to the end of the backup, to ensure the backup is complete before the command returns. 

!!! Note: 
    Since the cron job is doing this periodically in the background, the WAL segments you see listed may be different than the output listed above!

Verify that it completed by listing backups for the server:

```shell
barman list-backup pg
__OUTPUT__
pg 20240117T052502 - Wed Jan 17 05:25:21 2024 - Size: 54.1 MiB - WAL Size: 0 B
```
(the timestamps will be different for you)

Of course, we've configured streaming backups - so we shouldn't need to depend on having a base backup for every change made to the database. Let's make a small modification to the data and verify that it arrives. 

First, log into the database (we'll use our barman user for convenience in this demonstration):

```shell
psql -h pg -d pagila -U barman
__OUTPUT__
psql (16.1 (Ubuntu 16.1-1.pgdg22.04+1))
Type "help" for help.
```

Then make a modifications, and view the results:

```sql
Update actor Set first_name='ALOYSIUS' where actor_id=23;
Select * From actor Where last_name='KILMER';
\q
__OUTPUT__
UPDATE 1
 actor_id | first_name | last_name |          last_update          
----------+------------+-----------+-------------------------------
       45 | REESE      | KILMER    | 2022-02-15 09:34:33+00
       55 | FAY        | KILMER    | 2022-02-15 09:34:33+00
      153 | MINNIE     | KILMER    | 2022-02-15 09:34:33+00
      162 | OPRAH      | KILMER    | 2022-02-15 09:34:33+00
       23 | ALOYSIUS   | KILMER    | 2024-01-17 05:28:34.621217+00
(5 rows)
```

Ok, let's see if it showed up:

```shell
grep 'ALOYSIUS' ~/pg/streaming/*
__OUTPUT__
grep: /var/lib/barman/pg/streaming/000000010000000000000005.partial: binary file matches
```

There it is! The current WAL segment hasn't been rotated yet, but we have the most recent data in the *partial* WAL streamed to Barman. So in theory, nothing would be lost if something *terrible* happened to the database right now... 

Now, the crucial question with backups is always the same: "can you get the data *back?*"

We'll answer this in [Step #4: Restoring a Backup](step04-restore).
