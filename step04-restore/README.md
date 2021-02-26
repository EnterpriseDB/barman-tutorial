docker-compose up -d
docker exec -it backup -u barman /bin/bash

# Restoring a Backup With Barman

It's not a real backup until you've restored it - so let's end with that. 

Something terrible has happened to our example database! This should list all the tables:

```shell
psql -h pg -d pagila -U barman -c '\dt'
__OUTPUT__
Did not find any relations.
```

All the data is gone! OH THE HUMANITY!

Ok, I just didn't populate the data for this step, to demonstrate a total loss. Fortunately, we still have a backup!

```shell
barman list-backup pg
```

Let's instruct Barman to ssh into the database server and restore the backup. 

1. Connect to pg and shut down the database cluster:

    ```shell
    ssh postgres@pg /usr/lib/postgresql/13/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data stop
    ```

2. Instruct Barman to connect to pg and restore the latest backup 
    ```shell
    barman recover --remote-ssh-command 'ssh postgres@pg' \
            pg latest \
            /var/lib/postgresql/data
    ```

3. Restart the server:

    ```shell
    ssh postgres@pg /usr/lib/postgresql/13/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data start > /dev/null 2> /dev/null
    ```

Now we should be able to reconnect to the database:

```shell
psql -h pg -d pagila -U barman
__OUTPUT__
psql (13.2 (Ubuntu 13.2-1.pgdg20.04+1))
Type "help" for help.

pagila=#
```

...And re-run the query we started out with:

```sql
select * from actor where last_name='KILMER';
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

<!-- This needs barman-cli on the database server - which means I can't use the std postgresql image. TODO!

Ok, so far so good - but, we're missing the update we wrote to this data! Remember, that wasn't in the base backup, it was in a partial WAL file... Fortunately, Barman still has it and knows how to use it. 

Let's try this recovery process again:

1. Connect to pg and shut down the database cluster:

    ```shell
    ssh postgres@pg /usr/lib/postgresql/13/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data stop
    ```

2. Instruct Barman to connect to pg and restore the latest backup 
    ```shell
    barman recover --remote-ssh-command 'ssh postgres@pg' \
            --get-wal \
            pg latest \
            /var/lib/postgresql/data
    ```

3. Restart the server:

    ```shell
    ssh postgres@pg /usr/lib/postgresql/13/bin/pg_ctl \
        --pgdata=/var/lib/postgresql/data start &
    ```
-->

## Conclusion

This walk-through barely scratches the surface of what is possible with Barman, but hopefully it has provided you with a taste of its capabilities! For more details, visit https://pgbarman.org/
