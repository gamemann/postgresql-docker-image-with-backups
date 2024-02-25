This is a custom Docker image based off of the PostgreSQL Docker image [here](https://github.com/docker-library/postgres). This image uses [Supervisor](http://supervisord.org/) to start both Cron and the PostgreSQL server.

Additionally, a cron job is installed inside of the image ([`image/conf/cron.conf`](./image/conf/cron.conf)) that executes a backup script written in Bash ([`image/scripts/backup.sh`](./image/scripts/backup.sh)). The backup script dumps the database `$POSTGRES_DB` with the user `$POSTGRES_USER` to `/tmp/dbname.pgsql`. Afterwards, it uploads the database dump to a [Backblaze B2](https://www.backblaze.com/cloud-storage) bucket using [Duplicity](https://duplicity.us/) and deletes the local database dump.

The image itself is stored inside of the [`image/`](./image) directory. There is also a Docker Compose application you can refer to/use inside of the [`app/`](./app) directory which shows how to utilize this image.

## Installation
### Image
The image is stored in the [`image/`](./image) directory. You can use the `build_image.sh` Bash script to build the Docker image with the name/tag `postgresbackups:latest`. The following arguments are supported.

| Flag | Default | Description |
| ---- | ------- | ----------- |
| `--name=<NAME>` | `postgresbackups` | The name of the Docker image. |
| `--tag=<TAG>` | `latest` | The tag to set the Docker image to. |
| `--path=<PATH>` | `image/` | Builds the Docker image inside of `<PATH>`. |
| `--ptag=<TAG>` | `latest` | Builds Docker image based off of the PostgreSQL image with the tag `<TAG>`. |
| `--no-cache` | - | Builds the Docker image with no cache. |
| `--help` | - | Prints the help menu. |

You may also build the image manually using the following command as root (or using `sudo`).

```bash
docker build -t postgresbackups:latest image
```

### Application
The application ([`app/`](./app)) uses Docker Compose with the latest backup image built above. Before using this, please make sure you have created a `db-data/` directory where the `docker-compose.yml` file resides. This directory is mounted to `/var/lib/postgresql/data` inside of the Docker container and stores database-specific files.

You may also need to change the owner of the `db-data/` directory to the system user (`999`) via the `chown -R 999 db-data` command since the `postgres` user inside of the Docker container has a GUID of `999` by default (at least in my cases while testing).

With that said, make sure to copy or rename [`app/.env.example`](./app/.env.example) to `app/.env`!

Feel free to implement the application into your existing Docker Compose projects!

Read [configuration](#configuration) for more information on setting up the project.

## Configuration
All configuration is done using environmental variables inside of the Docker container. In the Docker Compose application inside this repository ([`app/`](./app)), we store the environmental variables inside of the [`app/.env`](./app/.env.example) file. By default, the file is called `.env.example`. Therefore, make sure to rename or copy it to `.env`.

Here are a list of environmental variables you should pay attention to and configure.

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
| BACKUP_B2_DIR | `testdb` | The directory to save the backup to inside of the B2 bucket. Use an empty string if you want to save it to the root of the bucket. |
| BACKUP_DUP_FORCE_INC | `0` | Forces Duplicity to perform an incremental backup. |
| BACKUP_DUP_FORCE_FULL | `0` | Forces Duplicity to perform a full backup. |
| BACKUP_DUP_PASS | `12345` | This is the GnuPG passphrase which is required for restoring the backup. Change this! |

By default, the cron job is ran every day at 12:00 midnight. However, you can easily change this by editing the [`image/conf/cron.conf`](./image/conf/cron.conf) file and rebuilding the image. You can use a cron generator tool such as [this](https://crontab.cronhub.io/) for assistance!

Additionally, you may edit the application's PostgreSQL server's configuration by editing the [`app/conf/postgresql.conf`](./app/conf/postgresql.conf) file and rebuilding the Docker container.

## Application Logging
The [`app/logs/`](./app/logs) directory is mounted as a volume to `/var/log/backups` inside of the Docker container. Therefore, logs should persist in this directory between rebuilds and restarts of the Docker container assuming the `$BACKUP_LOG_DIR` environmental variable is set to `/var/log/backups`.

## Duplicity
The Duplicity command/functionality used to upload the database dump to the Backblaze B2 bucket is fairly simple and shown below.

```bash
DUP_CMD=""

if [[ "$BACKUP_DUP_FORCE_INC" -ge 1 ]]; then
    DUP_CMD="inc"
elif [[ "BACKUP_DUP_FORCE_FULL" -ge 1 ]]; then
    DUP_CMD="full"
fi

DIR=

if [[ -n "$BACKUP_B2_DIR" ]]; then
    DIR="/${BACKUP_B2_DIR}"
fi

env PASSPHRASE="$BACKUP_DUP_PASS" duplicity $DUP_CMD "$FULL_DUMP_PATH" "b2://${BACKUP_B2_ID}:${BACKUP_B2_APP_KEY}@${BACKUP_B2_BUCKET}${DIR}"
```

If you need any flags, etc. added to this command, you may edit the [`image/scripts/backup.sh`](./image/scripts/backup.sh) Bash script and rebuild the Docker container.

## Executing Backup Script Manually
You can start a shell inside of the Docker container using the following command.

```bash
docker exec -it <container ID or name> bash
```

You can retrieve the container ID or name via the `docker container ls` command after starting the container.

Afterwards, you can execute the backup Bash script manually at `/opt/backup.sh` to test if things are working properly without needing to adjust/wait for the cron job.

Additionally, the environmental variables inside of the [`app/.env`](./app/.env.example) file should be set inside of this shell. You can confirm this by executing the `printenv` command.

## Credits
* [Christian Deacon](https://github.com/gamemann)