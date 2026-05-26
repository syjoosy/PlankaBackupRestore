#!/bin/bash

set -euo pipefail

# ========================
# CONFIG
# ========================
APP_DIR="/var/www/planka"
BACKUP_DIR="/home/pi/backups/planka"
DB_NAME="planka"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
TMP_DIR="$BACKUP_DIR/tmp_$DATE"
FINAL_FILE="$BACKUP_DIR/planka_backup_$DATE.tar.gz"
LOG_FILE="$BACKUP_DIR/backup_$DATE.log"

# FTP Settings
FTP_HOST="IP"
FTP_USER="USERNAME"
FTP_PASS="PASSWORD"

# ========================
# LOG FUNCTION
# ========================
log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"
mkdir -p "$TMP_DIR"

log "🚀 Starting Planka backup"
log "📦 Backup dir: $BACKUP_DIR"
log "📁 Temp dir: $TMP_DIR"
log "🕒 Date: $DATE"

# ========================
# 1. DB DUMP
# ========================
log "🗄️ Dumping PostgreSQL database: $DB_NAME"

sudo -u postgres bash -c "
  cd /tmp
  pg_dump $DB_NAME
" > "$TMP_DIR/db.sql"

log "✅ Database dump completed"

# ========================
# 2. APP ARCHIVE
# ========================
log "📦 Archiving application from $APP_DIR"

tar -czf "$TMP_DIR/app.tar.gz" -C "$APP_DIR" .

log "✅ Application archived"

# ========================
# 3. SYSTEMD UNIT
# ========================
log "⚙️ Saving systemd service file"

cp /etc/systemd/system/planka.service "$TMP_DIR/"

# ========================
# 4. FINAL PACKAGING
# ========================
log "📦 Creating final archive: $FINAL_FILE"

tar -czf "$FINAL_FILE" -C "$TMP_DIR" .

# ========================
# 5. FTP UPLOAD
# ========================
log "☁️ Uploading backup to FTP"

lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" <<EOF >> "$LOG_FILE" 2>&1
set ssl:verify-certificate no
put $FINAL_FILE
bye
EOF

log "✅ FTP upload completed"

# ========================
# 6. CLEANUP
# ========================
log "🧹 Cleaning temporary files"
rm -rf "$TMP_DIR"

log "🎉 Backup completed successfully!"
log "📁 File: $FINAL_FILE"