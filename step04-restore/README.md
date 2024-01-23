docker-compose up -d
docker exec -it -u barman backup /bin/bash

# Restoring a Backup With Barman


In the previous step, [we created a full backup of the example database](step03-backup). But it's not a real backup until we've successfully restored it - so let's end with that. 

Something terrible has happened to our example database! This should list all the tables:

```shell
psql -h pg -d pagila -U barman -c '\dt'
__OUTPUT__
Did not find any relations.
```

All the data is gone! 

Ok, I just didn't populate the data for this step, in order to demonstrate a total loss. Fortunately, we still have a backup!

```shell
barman list-backup pg
__OUTPUT__
pg 20240117T052502 - Wed Jan 17 05:25:21 2024 - Size: 54.1 MiB - WAL Size: 0 B
```

Before we do anything else, let's make sure our current backup doesn't get touched by stopping barman's streaming archiver. If we start restoring backups without doing this, there's a chance we could start injesting WAL files that conflict with those we've already recieved; while Barman works with PostgreSQL to try to avoid this, there's still a chance of something going wrong, so better safe than sorry:

1. Disable barman's cron job by renaming the file:

   ```shell
   sudo mv /etc/cron.d/barman /etc/cron.d/barman.bak
   ```

   !!! Note "Other cron jobs"
   In a real-world situation, you might have other cron jobs that you'd want to disable here,
   for instance a job that runs `barman backup`.
   !!!
2. Stop the running recieve-wal client (if one exists)
   ```shell
   barman receive-wal --stop pg
   ```
   (If you see a "no such process" error here, that's fine - just means the process wasn't currently running.)

With that done, let's instruct Barman to ssh into the database server and restore the backup. 


1. Connect to pg and shut down the database cluster:

    ```shell
    ssh postgres@pg /usr/lib/postgresql/16/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data stop
    __OUTPUT__
    waiting for server to shut down.... done
    server stopped
    ```

2. Back up the corrupt data directory, just in case something goes wrong. Then delete the corrupt data.

    ```shell
    ssh postgres@pg "cp -a /var/lib/postgresql/data \
        /var/lib/postgresql/old_data \
        && rm -rf /var/lib/postgresql/data/*"
    ```

3. Use [Barman's recover command](http://docs.pgbarman.org/release/3.9.0/#recover) to connect to pg and restore the latest base backup 

    ```shell
    barman recover --remote-ssh-command 'ssh postgres@pg' \
            pg latest \
            /var/lib/postgresql/data
    __OUTPUT__
    Starting remote restore for server pg using backup 20240117T052502
    Destination directory: /var/lib/postgresql/data
    Remote command: ssh postgres@pg
    Using safe horizon time for smart rsync copy: 2024-01-17 05:25:02.456655+00:00
    Copying the base backup.
    Copying required WAL segments.
    Generating archive status files
    Identify dangerous settings in destination directory.

    Recovery completed (start time: 2024-01-17 05:35:04.908923+00:00, elapsed time: 3 seconds)
    Your PostgreSQL server has been successfully prepared for recovery!
    ```

    Barman handles connecting to the destination server, but we do have to provide a valid path *on* that server. In this example, the PostgreSQL cluster lives in /var/lib/postgresql/data and we're asking Barman to overwrite it with the backup.

4. Restart the server:

    ```shell
    ssh postgres@pg "/usr/lib/postgresql/16/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data \
        -l /var/log/postgresql/pg.log \
        start \
        ; timeout 3 tail -f /var/log/postgresql/pg.log"
    __OUTPUT__
    waiting for server to start.... done
    server started
    2024-01-17 05:36:00.491 UTC [292] LOG:  listening on IPv4 address "0.0.0.0", port 5432
    2024-01-17 05:36:00.491 UTC [292] LOG:  listening on IPv6 address "::", port 5432
    2024-01-17 05:36:00.497 UTC [292] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
    2024-01-17 05:36:00.504 UTC [295] LOG:  database system was interrupted; last known up at 2024-01-17 05:25:16 UTC
    2024-01-17 05:36:01.016 UTC [295] LOG:  redo starts at 0/4000028
    2024-01-17 05:36:01.021 UTC [295] LOG:  consistent recovery state reached at 0/4000100
    2024-01-17 05:36:01.021 UTC [295] LOG:  redo done at 0/4000100 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
    2024-01-17 05:36:01.066 UTC [293] LOG:  checkpoint starting: end-of-recovery immediate wait
    2024-01-17 05:36:01.106 UTC [293] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 1 recycled; write=0.010 s, sync=0.004 s, total=0.045 s; sync files=2, longest=0.003 s, average=0.002 s; distance=16384 kB, estimate=16384 kB; lsn=0/5000028, redo lsn=0/5000028
    2024-01-17 05:36:01.116 UTC [292] LOG:  database system is ready to accept connections
    ```

Now we should be able to reconnect to the database:

```shell
psql -h pg -d pagila -U barman
__OUTPUT__
psql (16.1 (Ubuntu 16.1-1.pgdg22.04+1))
Type "help" for help.

pagila=# 
```

...And re-run the query we started out with:

```sql
select * from actor where last_name='KILMER';
\q
__OUTPUT__
 actor_id | first_name | last_name |      last_update       
----------+------------+-----------+------------------------
       23 | SANDRA     | KILMER    | 2022-02-15 09:34:33+00
       45 | REESE      | KILMER    | 2022-02-15 09:34:33+00
       55 | FAY        | KILMER    | 2022-02-15 09:34:33+00
      153 | MINNIE     | KILMER    | 2022-02-15 09:34:33+00
      162 | OPRAH      | KILMER    | 2022-02-15 09:34:33+00
(5 rows)
```

Ok, so far so good - but, we're missing the update we wrote to this data! Remember, that wasn't in the base backup, it was in a partial WAL file... Fortunately, Barman still has it and knows how to use it. 

Let's try this recovery process again:

1. Connect to pg and shut down the database cluster:

    ```shell
    ssh postgres@pg /usr/lib/postgresql/16/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data stop
    __OUTPUT__
    waiting for server to shut down.... done
    server stopped
    ```

2. Back up the corrupt data directory, just in case something goes wrong. Then delete the corrupt data.

    ```shell
    ssh postgres@pg "cp -a /var/lib/postgresql/data \
        /var/lib/postgresql/old_data \
        && rm -rf /var/lib/postgresql/data/*"
    ```

3. Instruct Barman to connect to pg and restore the latest backup 
    ```shell
    barman recover --remote-ssh-command 'ssh postgres@pg' \
            --get-wal \
            --target-tli current \
            pg latest \
            /var/lib/postgresql/data
    __OUTPUT__
    Starting remote restore for server pg using backup 20240117T052502
    Destination directory: /var/lib/postgresql/data
    Remote command: ssh postgres@pg
    Using safe horizon time for smart rsync copy: 2024-01-17 05:25:02.456655+00:00
    Copying the base backup.
    Generating recovery configuration
    Identify dangerous settings in destination directory.

    WARNING: 'get-wal' is in the specified 'recovery_options'.
    Before you start up the PostgreSQL server, please review the postgresql.auto.conf file
    inside the target directory. Make sure that 'restore_command' can be executed by the PostgreSQL user.

    Recovery completed (start time: 2024-01-17 05:38:07.678341+00:00, elapsed time: 3 seconds)
    Your PostgreSQL server has been successfully prepared for recovery!
    ```

    The new options here are `--get-wal` and `--target-tli`
    - `--get-wal` configures PostgreSQL to fetch necessary WAL files via Barman's `get-wal` command *and also passes the `--partial` option to `get-wal`* - this gives us our best shot at being able to recover data that was successfully streamed to Barman but not part of a complete WAL file.
    - `--target-tli current` specifies that we want the timeline that was current when we took our base backup. That's also the only timeline we have, so this isn't *strictly* necessary... But in real-world situations we might need to be precise here - it's a good habit to get into.

4. Restart the server:

    ```shell
    ssh postgres@pg "/usr/lib/postgresql/16/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data \
        -l /var/log/postgresql/pg.log \
        start \
        ; timeout 5 tail -f /var/log/postgresql/pg.log"
    __OUTPUT__
    waiting for server to start..... done
    server started
    2024-01-17 05:41:15.492 UTC [555] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
    2024-01-17 05:41:15.497 UTC [558] LOG:  database system was interrupted; last known up at 2024-01-17 05:25:16 UTC
    2024-01-17 05:41:15.778 UTC [558] LOG:  starting archive recovery
    2024-01-17 05:41:16.359 UTC [558] LOG:  restored log file "000000010000000000000004" from archive
    2024-01-17 05:41:16.403 UTC [558] LOG:  redo starts at 0/4000028
    2024-01-17 05:41:17.024 UTC [558] LOG:  restored log file "000000010000000000000005" from archive
    2024-01-17 05:41:17.059 UTC [558] LOG:  consistent recovery state reached at 0/4000100
    2024-01-17 05:41:17.059 UTC [558] LOG:  invalid resource manager ID 112 at 0/5000150
    2024-01-17 05:41:17.059 UTC [558] LOG:  redo done at 0/50000D8 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.65 s
    2024-01-17 05:41:17.059 UTC [555] LOG:  database system is ready to accept read-only connections
    2024-01-17 05:41:18.206 UTC [558] LOG:  restored log file "000000010000000000000005" from archive
    ERROR: WAL file '00000002.history' not found in server 'pg' (SSH host: 172.21.0.2)
    ERROR: Remote 'barman get-wal' command has failed!
    2024-01-17 05:41:19.204 UTC [558] LOG:  selected new timeline ID: 2
    ERROR: WAL file '00000001.history' not found in server 'pg' (SSH host: 172.21.0.2)
    ERROR: Remote 'barman get-wal' command has failed!
    2024-01-17 05:41:20.385 UTC [558] LOG:  archive recovery complete
    2024-01-17 05:41:20.388 UTC [556] LOG:  checkpoint starting: end-of-recovery immediate wait
    2024-01-17 05:41:20.410 UTC [556] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 1 recycled; write=0.006 s, sync=0.002 s, total=0.025 s; sync files=2, longest=0.002 s, average=0.001 s; distance=16384 kB, estimate=16384 kB; lsn=0/5000150, redo lsn=0/5000150
    2024-01-17 05:41:20.412 UTC [555] LOG:  database system is ready to accept connections
    ```

!!! Note about those errors...
You may notice a few lines starting with "ERROR:" mid-way through the recovery log. They're fine - that's just PostgreSQL scanning to make sure it has the most recent timeline.
By going through this recovery, we've actually created a *new* timeline - note the message,

> LOG:  selected new timeline ID: 2

If you were to take another backup (`barman backup pg --wait`) and then run through the four steps above again, you'd see that now `00000002.history` is found and PostgreSQL goes looking for `00000003.history`... Try it!

These "timelines" help avoid a situation where you might inadvertently lose data doing a Point-In-Time Recovery (PITR) with backups running. While we disabled barman's streaming archiver at the outset [to avoid a particular pitfall](https://github.com/EnterpriseDB/barman/issues/542), in practice you'll likely want to get your database back into operation *with backups* fairly quickly.

For more on PostgreSQL timelines, see [Continuous Archiving in the PostgreSQL documentation](https://www.postgresql.org/docs/current/continuous-archiving.html#BACKUP-TIMELINES).
!!!

Now check the data again:

```shell
psql -h pg -d pagila -U barman -c \
    "select * from actor where last_name='KILMER'"
__OUTPUT__
actor_id | first_name | last_name |          last_update          
----------+------------+-----------+-------------------------------
       45 | REESE      | KILMER    | 2022-02-15 09:34:33+00
       55 | FAY        | KILMER    | 2022-02-15 09:34:33+00
      153 | MINNIE     | KILMER    | 2022-02-15 09:34:33+00
      162 | OPRAH      | KILMER    | 2022-02-15 09:34:33+00
       23 | ALOYSIUS   | KILMER    | 2024-01-17 05:28:34.621217+00
(5 rows)
```

Good ol' Aloysius is back!

## Conclusion

This demonstration barely scratches the surface of what is possible with Barman, but hopefully it has provided you with a taste of its capabilities! For more details, visit https://pgbarman.org/
