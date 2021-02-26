docker-compose up -d
docker exec -it backup -u barman /bin/bash

# Running Backups With Barman

Running a full backup (or "base backup") can be performed at any time using the `backup` command:

```shell
barman backup pg --wait
__OUTPUT__
Starting backup using postgres method for server pg in /var/lib/barman/pg/base/20210226T003857
Backup start at LSN: 0/23EA6C0 (000000010000000000000002, 003EA6C0)
Starting backup copy via pg_basebackup for 20210226T003857
Copy done (time: 1 second)
Finalising the backup.
This is the first backup for server pg
WAL segments preceding the current backup have been found:
        000000010000000000000002 from server pg has been removed
Backup size: 38.5 MiB
Backup end at LSN: 0/4000000 (000000010000000000000003, 00000000)
Backup completed (start time: 2021-02-26 00:38:57.535973, elapsed time: 2 seconds)
Waiting for the WAL file 000000010000000000000003 from server 'pg'
Processing xlog segments from streaming for pg
        000000010000000000000002
        000000010000000000000003
```

This will wait to recieve the next WAL file to ensure the backup is complete before the command returns.

Verify that it completed by listing backups for the server:

```shell
barman list-backup pg
__OUTPUT__
pg 20210226T003857 - Fri Feb 26 00:38:59 2021 - Size: 54.5 MiB - WAL Size: 0 B
```
(the timestamps will be different for you)

<!-- This needs barman-cli on the database server - which means I can't use the std postgresql image. TODO!

Of course, we've configured streaming backups - so we shouldn't need to depend on having a base backup for every change made to the database. Let's make a small modification to the data and verify that it arrives. 

First, log into the database (we'll use our barman user for convenience in this demonstration):

```shell
psql -h pg -d pagila -U barman
```

Then make a modifications, and view the results:

```sql
Update actor Set first_name='ALOYSIUS' where actor_id=23;
Select * From actor Where last_name='KILMER';
/q
```

Ok, let's see if it showed up:

```shell
grep 'ALOYSIUS' pg/streaming/*
```

There it is! The current WAL segment hasn't been rotated yet, but we have the most recent data in the *partial* WAL streamed to Barman. So in theory, nothing would be lost of something *terrible* happened to the database right now... 

--->

Now, the crucial question with backups is always the same: "can you get the data *back?*"

We'll answer this in [Step #4: Restoring a Backup](step03-restore).
