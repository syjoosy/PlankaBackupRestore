# PlankaBackupRestore
This repository contains scripts to backup and restore planka

## Backup

### Manual:
```
./backup_planka.sh
```

### Automatic:

Cron:
```
crontab -e
```

Backup everyday at 4AM (with logs saving):
```
0 4 * * * /YOUR_PATH/backup_planka.sh >> /YOUR_PATH/backups/planka/cron.log 2>&1
```

## Restore

### Manual:
```
./restore_planka.sh /YOUR_PATH/backups/planka/planka_backup_2026-05-13_10-45-02.tar.gz 
```