#!/bin/bash

set -euo pipefail

# ========================
# CONFIG
# ========================
APP_DIR="/var/www/planka"
BACKUP_FILE="${1:-}"

DB_NAME="planka"
SERVICE_NAME="planka.service"

WORKDIR="/tmp/planka_restore"

# ========================
# CHECK INPUT
# ========================
if [[ -z "$BACKUP_FILE" ]]; then
  echo "❌ Usage: $0 /path/to/planka_backup.tar.gz"
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "❌ Backup file not found: $BACKUP_FILE"
  exit 1
fi

# ========================
# PREP
# ========================
echo "🚀 Starting Planka restore"
echo "📦 Backup: $BACKUP_FILE"

sudo mkdir -p "$WORKDIR"
sudo rm -rf "$WORKDIR"/*

# ========================
# STOP SERVICE
# ========================
echo "🛑 Stopping service: $SERVICE_NAME"
sudo systemctl stop "$SERVICE_NAME" || true

# ========================
# EXTRACT BACKUP
# ========================
echo "📦 Extracting backup..."

sudo tar -xzf "$BACKUP_FILE" -C "$WORKDIR"

# ========================
# FIND FILES
# ========================
DB_DUMP=$(find "$WORKDIR" -name "db.sql" | head -n 1)
APP_ARCHIVE=$(find "$WORKDIR" -name "app.tar.gz" | head -n 1)
SERVICE_FILE=$(find "$WORKDIR" -name "planka.service" | head -n 1)

if [[ -z "$DB_DUMP" || -z "$APP_ARCHIVE" ]]; then
  echo "❌ Backup is missing required files (db.sql or app.tar.gz)"
  exit 1
fi

# ========================
# RESTORE DATABASE
# ========================
echo "🗄️ Restoring PostgreSQL database: $DB_NAME"

sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"

sudo -u postgres psql "$DB_NAME" < "$DB_DUMP"

echo "✅ Database restored"

# ========================
# RESTORE APP
# ========================
echo "📁 Restoring application to $APP_DIR"

sudo rm -rf "$APP_DIR"
sudo mkdir -p "$APP_DIR"

sudo tar -xzf "$APP_ARCHIVE" -C "$APP_DIR"

echo "✅ Application restored"

# ========================
# RESTORE SYSTEMD SERVICE
# ========================
if [[ -n "$SERVICE_FILE" ]]; then
  echo "⚙️ Restoring systemd service"

  sudo cp "$SERVICE_FILE" "/etc/systemd/system/$SERVICE_NAME"
  sudo systemctl daemon-reload

  echo "✅ Systemd service restored"
fi

# ========================
# FIX PERMISSIONS (optional but useful)
# ========================
echo "🔧 Fixing permissions"

sudo chown -R www-data:www-data "$APP_DIR" || true

# ========================
# START SERVICE
# ========================
echo "🚀 Starting service"

sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# ========================
# CLEANUP
# ========================
echo "🧹 Cleaning up"
sudo rm -rf "$WORKDIR"

echo "🎉 Restore completed successfully!"