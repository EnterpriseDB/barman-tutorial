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
pg 20231018T054305 - Wed Oct 18 05:43:09 2023 - Size: 69.5 MiB - WAL Size: 0 B
```

Let's instruct Barman to ssh into the database server and restore the backup. 

1. Connect to pg and shut down the database cluster:

    ```shell
    ssh postgres@pg /usr/lib/postgresql/15/bin/pg_ctl \
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

3. Use [Barman's recover command](http://docs.pgbarman.org/release/2.12/#recover) to connect to pg and restore the latest backup 

    ```shell
    barman recover --remote-ssh-command 'ssh postgres@pg' \
            pg latest \
            /var/lib/postgresql/data
    __OUTPUT__
    Starting remote restore for server pg using backup 20231018T054305
    Destination directory: /var/lib/postgresql/data
    Remote command: ssh postgres@pg
    Copying the base backup.
    Copying required WAL segments.
    Generating archive status files
    Identify dangerous settings in destination directory.

    Recovery completed (start time: 2023-10-18 05:48:52.095585+00:00, elapsed time: 3 seconds)
    Your PostgreSQL server has been successfully prepared for recovery!
    ```

    Barman handles connecting to the destination server, but we do have to provide a valid path *on* that server. In this example, the PostgreSQL cluster lives in /var/lib/postgresql/data and we're asking Barman to overwrite it with the backup.

4. Restart the server:

    ```shell
    ssh postgres@pg "/usr/lib/postgresql/15/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data \
        -l /var/log/postgresql/pg.log \
        start \
        ; tail /var/log/postgresql/pg.log"
    __OUTPUT__
    waiting for server to start.... done
    server started
    2023-10-18 05:28:59.307 UTC [361] LOG:  listening on IPv4 address "0.0.0.0", port 5432
    2023-10-18 05:28:59.307 UTC [361] LOG:  listening on IPv6 address "::", port 5432
    2023-10-18 05:28:59.311 UTC [361] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
    2023-10-18 05:28:59.318 UTC [364] LOG:  database system was interrupted; last known up at 2023-10-18 05:16:43 UTC
    2023-10-18 05:28:59.922 UTC [364] LOG:  redo starts at 0/3000028
    2023-10-18 05:28:59.922 UTC [364] LOG:  consistent recovery state reached at 0/3000100
    2023-10-18 05:28:59.922 UTC [364] LOG:  redo done at 0/4000060 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
    2023-10-18 05:28:59.944 UTC [362] LOG:  checkpoint starting: end-of-recovery immediate wait
    2023-10-18 05:28:59.962 UTC [362] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 2 recycled; write=0.003 s, sync=0.002 s, total=0.020 s; sync files=2, longest=0.001 s, average=0.001 s; distance=32768 kB, estimate=32768 kB
    2023-10-18 05:28:59.967 UTC [361] LOG:  database system is ready to accept connections
    ```

Now we should be able to reconnect to the database:

```shell
psql -h pg -d pagila -U barman
__OUTPUT__
psql (16.0 (Ubuntu 16.0-1.pgdg20.04+1), server 15.4 (Debian 15.4-2.pgdg120+1))
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
       23 | SANDRA     | KILMER    | 2020-02-15 09:34:33+00
       45 | REESE      | KILMER    | 2020-02-15 09:34:33+00
       55 | FAY        | KILMER    | 2020-02-15 09:34:33+00
      153 | MINNIE     | KILMER    | 2020-02-15 09:34:33+00
      162 | OPRAH      | KILMER    | 2020-02-15 09:34:33+00
(5 rows)
```

Ok, so far so good - but, we're missing the update we wrote to this data! Remember, that wasn't in the base backup, it was in a partial WAL file... Fortunately, Barman still has it and knows how to use it. 

Let's try this recovery process again:

1. Connect to pg and shut down the database cluster:

    ```shell
    ssh postgres@pg /usr/lib/postgresql/15/bin/pg_ctl \
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
            pg latest \
            /var/lib/postgresql/data
    __OUTPUT__
    Starting remote restore for server pg using backup 20231018T054305
    Destination directory: /var/lib/postgresql/data
    Remote command: ssh postgres@pg
    Using safe horizon time for smart rsync copy: 2023-10-18 05:16:43.432672+00:00
    Copying the base backup.
    Generating recovery configuration
    Identify dangerous settings in destination directory.

    WARNING: 'get-wal' is in the specified 'recovery_options'.
    Before you start up the PostgreSQL server, please review the postgresql.auto.conf file
    inside the target directory. Make sure that 'restore_command' can be executed by the PostgreSQL user.

    Recovery completed (start time: 2023-10-18 05:49:44.893295+00:00, elapsed time: 3 seconds)
    Your PostgreSQL server has been successfully prepared for recovery!
    ```

4. Restart the server:

    ```shell
    ssh postgres@pg "/usr/lib/postgresql/15/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data \
        -l /var/log/postgresql/pg.log \
        start \
        ; tail /var/log/postgresql/pg.log"
    __OUTPUT__
    waiting for server to start...... done
    server started
    2023-10-18 05:51:52.439 UTC [501] LOG:  starting archive recovery
    2023-10-18 05:51:52.906 UTC [501] LOG:  restored log file "000000010000000000000003" from archive
    2023-10-18 05:51:52.933 UTC [501] LOG:  redo starts at 0/3000028
    2023-10-18 05:51:53.417 UTC [501] LOG:  restored log file "000000010000000000000004" from archive
    2023-10-18 05:51:54.046 UTC [501] LOG:  restored log file "000000010000000000000005" from archive
    2023-10-18 05:51:54.068 UTC [501] LOG:  consistent recovery state reached at 0/3000100
    2023-10-18 05:51:54.068 UTC [498] LOG:  database system is ready to accept read-only connections
    2023-10-18 05:51:54.077 UTC [501] LOG:  invalid record length at 0/50ACF38: wanted 24, got 0
    2023-10-18 05:51:54.077 UTC [501] LOG:  redo done at 0/50ACF00 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 1.14 s
    2023-10-18 05:51:54.077 UTC [501] LOG:  last completed transaction was at log time 2023-10-18 05:43:44.343455+00
    ```

!!! Note about those errors...
    You may notice two lines starting with "ERROR:" mid-way through the recovery log. They're fine - that's just PostgreSQL scanning to make sure it has the most recent timeline.
    By going through this recovery, we've actually created a *new* timeline - in fact, if you were to run through the four steps above again, you'd see that now `00000002.history` is found and PostgreSQL goes looking for `00000003.history`... Try it!

    For more on PostgreSQL backup timelines, see [Continuous Archiving in the PostgreSQL documentation](https://www.postgresql.org/docs/current/continuous-archiving.html#BACKUP-TIMELINES).

Now check the data again:

```shell
psql -h pg -d pagila -U barman -c \
    "select * from actor where last_name='KILMER'"
__OUTPUT__
 actor_id | first_name | last_name |          last_update          
----------+------------+-----------+-------------------------------
       45 | REESE      | KILMER    | 2020-02-15 09:34:33+00
       55 | FAY        | KILMER    | 2020-02-15 09:34:33+00
      153 | MINNIE     | KILMER    | 2020-02-15 09:34:33+00
      162 | OPRAH      | KILMER    | 2020-02-15 09:34:33+00
       23 | ALOYSIUS   | KILMER    | 2021-03-30 04:06:55.101099+00
(5 rows)
```

Good ol' Aloysius is back!

## Conclusion

This demonstration barely scratches the surface of what is possible with Barman, but hopefully it has provided you with a taste of its capabilities! For more details, visit https://pgbarman.org/
