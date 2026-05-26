# PlankaBackupRestore
This repository contains scripts to backup and restore planka

## Backup
Backup script also contains auto FTP upload (Item 5 in the script).
To make the FTP upload work, you need to install the package:
```
sudo apt update
sudo apt install lftp
```

### Manual:
```
./backup.sh
```

### Automatic:

Cron:
```
crontab -e
```

Backup everyday at 4AM (with logs saving):
```
0 4 * * * /YOUR_PATH/backup.sh >> /YOUR_PATH/backups/planka/cron.log 2>&1
```

## Restore

### Manual:
```
./restore.sh /YOUR_PATH/backups/planka/planka_backup_2026-05-13_10-45-02.tar.gz 
```