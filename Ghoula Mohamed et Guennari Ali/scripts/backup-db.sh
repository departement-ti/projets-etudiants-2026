#!/bin/bash
# ── Sauvegarde MySQL — Rayhan ERP ──────────────────────────────
# Usage : ./scripts/backup-db.sh
# Cron  : 0 3 * * * /path/to/scripts/backup-db.sh
# ───────────────────────────────────────────────────────────────
set -e

BACKUP_DIR="$(dirname "$0")/../backups"
mkdir -p "$BACKUP_DIR"

docker exec rayhan-mysql mysqldump \
  -u root -prayhan_erp_2024 \
  --databases rayhan_erp_db \
  --add-drop-database \
  --routines --triggers \
  > "$BACKUP_DIR/rayhan_$(date +%Y%m%d_%H%M%S).sql"

echo "Backup saved: $BACKUP_DIR/rayhan_$(date +%Y%m%d_%H%M%S).sql"
