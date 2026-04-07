#!/bin/sh
# Periodic backups for the backup sidecar service.
set -eu

INTERVAL=${BACKUP_INTERVAL:-300}
echo "Starting backup loop: interval=${INTERVAL}s retention=${BACKUP_RETENTION:-30}"

while true; do
  /scripts/backup-n8n.sh || echo "Backup failed (will retry)" >&2
  sleep "$INTERVAL"
done
