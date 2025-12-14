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
log 3 "Using B2 bucket directory: $BACKUP_B2_DIR..."
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

DUP_CMD=""

if [[ "$BACKUP_DUP_FORCE_INC" -ge 1 ]]; then
    DUP_CMD="inc"
elif [[ "$BACKUP_DUP_FORCE_FULL" -ge 1 ]]; then
    DUP_CMD="full"
fi

DIR=

if [[ -n "$BACKUP_B2_DIR" ]]; then
    DIR="/${BACKUP_B2_DIR}"
fi

B2_URL="b2://${BACKUP_B2_ID}:${BACKUP_B2_APP_KEY}@${BACKUP_B2_BUCKET}${DIR}"

env PASSPHRASE="$BACKUP_DUP_PASS" duplicity $DUP_CMD --allow-source-mismatch "$FULL_DUMP_PATH" "$B2_URL"

# Remove local backup.
log 4 "Removing local backup file '$FULL_DUMP_PATH'..."
rm -f "$FULL_DUMP_PATH"

# Cleanup old backups
log 3 "Cleaning up old backups..."

BACKUP_DUP_RETENTION_DAYS=${BACKUP_DUP_RETENTION_DAYS:-30}
BACKUP_DUP_KEEP_FULL_CHAINS=${BACKUP_DUP_KEEP_FULL_CHAINS:-0}

# Keep only x full backup chains if enabled.
if [[ "$BACKUP_DUP_KEEP_FULL_CHAINS" -gt 0 ]]; then
    
    log 3 "Keeping last $BACKUP_DUP_KEEP_FULL_CHAINS full backup chains..."

    env PASSPHRASE="$BACKUP_DUP_PASS" duplicity remove-all-inc-of-but-n-full "$BACKUP_DUP_KEEP_FULL_CHAINS" --force "$B2_URL"
else
    # Remove backups older than x days.
    log 3 "Removing backups older than $BACKUP_DUP_RETENTION_DAYS days..."

    env PASSPHRASE="$BACKUP_DUP_PASS" duplicity remove-older-than "${BACKUP_DUP_RETENTION_DAYS}D" --force "$B2_URL"
fi

# Clean up unused files.
log 3 "Cleaning up unused/orphaned backup files..."
env PASSPHRASE="$BACKUP_DUP_PASS" duplicity cleanup --force "$B2_URL"

# Show collection status if needed.
if [[ "$BACKUP_VERBOSE" -ge 3 ]]; then
    log 3 "Current backup collection status:"

    env PASSPHRASE="$BACKUP_DUP_PASS" duplicity collection-status "$B2_URL"
fi

log 2 "Finished..."