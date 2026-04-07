#!/bin/sh
# Single backup run: SQLite online backup, archives n8n_data (excluding live DB files),
# Redis SAVE + archive. Writes to BACKUP_ROOT/$STAMP/.
set -eu

BACKUP_ROOT=${BACKUP_ROOT:-/backups}
N8N_DIR=${N8N_DIR:-/data/n8n}
REDIS_DIR=${REDIS_DIR:-/data/redis}
REDIS_HOST=${REDIS_HOST:-redis}
STAMP=$(date +%Y%m%d-%H%M%S)
DEST="$BACKUP_ROOT/$STAMP"
mkdir -p "$DEST"

{
  echo "timestamp=$STAMP"
  echo "Restore requires the same N8N_ENCRYPTION_KEY and N8N_USER_MANAGEMENT_JWT_SECRET as when this backup was created."
} >"$DEST/manifest.txt"

if [ -f "$N8N_DIR/database.sqlite" ]; then
  sqlite3 "$N8N_DIR/database.sqlite" ".backup ${DEST}/n8n-database.sqlite"
fi

tar -czf "$DEST/n8n_data.tar.gz" -C "$N8N_DIR" \
  --exclude='database.sqlite' \
  --exclude='database.sqlite-wal' \
  --exclude='database.sqlite-shm' \
  .

if [ -n "${REDIS_PASSWORD:-}" ]; then
  redis-cli -h "$REDIS_HOST" -a "$REDIS_PASSWORD" --no-auth-warning SAVE || true
fi
if [ -f "$REDIS_DIR/dump.rdb" ]; then
  cp "$REDIS_DIR/dump.rdb" "$DEST/redis-dump.rdb"
fi
tar -czf "$DEST/redis_data.tar.gz" -C "$REDIS_DIR" .

RETENTION=${BACKUP_RETENTION:-30}
case "$RETENTION" in
  ''|*[!0-9]*) RETENTION=30 ;;
esac
if [ "$RETENTION" -ge 1 ]; then
  ls -1t "$BACKUP_ROOT" 2>/dev/null | tail -n +$((RETENTION + 1)) | while read -r d; do
    [ -z "$d" ] && continue
    [ -d "$BACKUP_ROOT/$d" ] || continue
    rm -rf "$BACKUP_ROOT/$d"
  done
fi

echo "Backup completed: $DEST"
