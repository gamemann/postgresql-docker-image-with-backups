#!/bin/bash
PATH=$PATH:/usr/local/bin/

DATE_MORE=$(date +"%Y-%m-%d %H:%M:%S")
DATE_SIMPLE=$(date +"%Y-%m-%d")

# Log function.
log() {
    if [[ "$BACKUP_VERBOSE" -ge "$1" ]]; then
        echo "[$1][$DATE_MORE] $2"

        # Check for log file.
        if [[ -n "$BACKUP_LOG_DIR" ]]; then
            LOG_FILE="$BACKUP_LOG_DIR/$DATE_SIMPLE.log"

            echo "[$1][$DATE_MORE] $2" >> $LOG_FILE
        fi
    fi
}

log 2 "Starting backup on '$DATE_MORE'..."

log 3 "Using B2 key: $BACKUP_B2_APP_KEY..."
log 3 "Using B2 ID: $BACKUP_B2_ID..."
log 3 "Using B2 bucket: $BACKUP_B2_BUCKET..."
log 3 "Using PSQL User: $POSTGRES_USER..."
log 3 "Using PSQL DB: $POSTGRES_DB..."

# Make sure our environmental variables are set.
if [[ -z "$POSTGRES_USER" ]]; then
    log 0 "FATAL: PostgreSQL user not set!"

    exit 1
fi

if [[ -z "$POSTGRES_DB" ]]; then
    log 0 "FATAL: PostgreSQL database not set!"

    exit 1
fi

if [[ -z "$BACKUP_B2_ID" ]]; then
    log 0 "FATAL: B2 ID not set!"

    exit 1
fi

if [[ -z "$BACKUP_B2_APP_KEY" ]]; then
    log 0 "FATAL: B2 App Key not set!"

    exit 1
fi

if [[ -z "$BACKUP_B2_BUCKET" ]]; then
    log 0 "FATAL: B2 bucket not set!"

    exit 1
fi

# Dump database.
DUMP_FILE_NAME="${POSTGRES_DB}.pgsql"
FULL_DUMP_PATH="/tmp/${DUMP_FILE_NAME}"

log 3 "Backing up to file '$FULL_DUMP_PATH'..."

pg_dump -U $POSTGRES_USER -d $POSTGRES_DB > $FULL_DUMP_PATH

log 3 "Uploading to Backblaze..."

duplicity "$FULL_DUMP_PATH" "b2://${BACKUP_B2_ID}:${BACKUP_B2_APP_KEY}@${BACKUP_B2_BUCKET}"

# Remove local backup.
log 4 "Removing local backup file '$FULL_DUMP_PATH'..."
rm -f "$FULL_DUMP_PATH"

log 2 "Finished..."