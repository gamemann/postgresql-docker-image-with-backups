**Work in progress!**

This is a custom Docker image based off of the PostgreSQL Docker image [here](https://github.com/docker-library/postgres). This image uses [Supervisor](http://supervisord.org/) to start both Cron and the PostgreSQL server.

Additionally, a cron job is installed inside of the Docker container ([`conf/cron.conf`](./conf/cron.conf)) that executes a backup script written in Bash ([`scripts/backup.sh`](./scripts/backup.sh)). The backup script dumps the database `$POSTGRES_DB` with the user `$POSTGRES_USER` to `/tmp/dbname_YY-MM-DD.pgsql`. Afterwards, it uploads the database dump to a [Backblaze B2](https://www.backblaze.com/cloud-storage) bucket using [Duplicity](https://duplicity.us/) and deletes the local database dump.

## Installation
Before building and starting the Docker container, create a directory named `db-data` using the `mkdir db-data/` command which will store the PostgreSQL database information and be mounted to `/var/lib/postgresql/lib` inside of the Docker container.

Read [configuration](#configuration).

## Configuration
All configuration is done inside of the [`docker-compose.yml`](./docker-compose.yml) file using the following environmental variables.

| Name | Default | Description |
| ---- | ------- | ----------- |
| POSTGRES_USER | `testuser` | The PostgreSQL username (inherited from PostgreSQL image). |
| POSTGRES_PASSWORD | `testpass` | The PostgreSQL password (inherited from PostgreSQL image). |
| POSTGRES_DB | `testdb` | The PostgreSQL database name (inherited from PostgreSQL image). |
| BACKUP_VERBOSE | `1` | The backup script's verbose level. Log messages go up to verbose level `4` currently. |
| BACKUP_LOG_DIR | `/var/log/backups` | The backup script's log directory inside of the Docker container. Leave blank to disable logging to files. |
| BACKUP_B2_APP_KEY | `null` | The Backblaze B2 application master key. |
| BACKUP_B2_ID | `null` | The Backblaze B2 application master ID. |
| BACKUP_B2_BUCKET | `mybucket` | The Backblaze B2 bucket name to store backups in. |

By default, the cron job is ran every day at 12:00 midnight. However, you can easily change this by editing the [`conf/cron.conf`](./conf/cron.conf) file and rebuilding the container. You can use a cron generator tool such as [this](https://crontab.cronhub.io/) for assistance!

Additionally, you may edit the PostgreSQL server's configuration by editing the [`conf/postgresql.conf`](./conf/postgresql.conf) file and rebuilding the Docker container.

## Logging
The `logs/` directory is mounted as a volume to `/var/log/backups` inside of the Docker container. Therefore, logs should persist in this directory between rebuilds and restarts of the Docker container assuming `$BACKUP_LOG_DIR` is set to `/var/log/backups`.

## Duplicity
The Duplicity command used to upload the database dump to the Backblaze B2 bucket is very simple.

```bash
duplicity "$FULL_DUMP_PATH" "b2://${BACKUP_B2_ID}:${BACKUP_B2_APP_KEY}@${BACKUP_B2_BUCKET}"
```

If you need any flags, etc. added to this command, you may edit the [`scripts/backup.sh`](./scripts/backup.sh) Bash script and rebuild the Docker container.

## Executing Backup Script Manually
You can start a shell inside of the Docker container using the following command.

```bash
docker exec -it <container ID or name> bash
```

You can retrieve the container ID or name via the `docker container ls` command after starting the container.

Afterwards, you can execute the backup Bash script manually at `/opt/backup.sh` to test if things are working properly without needing to adjust/wait for the cron job.

Additionally, the environmental variables inside of the [`docker-compose.yml`](./docker-compose.yml) file should be set inside of this shell. You can confirm this by executing the `printenv` command.

## Credits
* [Christian Deacon](https://github.com/gamemann)