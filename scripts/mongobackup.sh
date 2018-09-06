#!/bin/bash

# gomnodb backup by afx

# 1. user mongo client to connect to the database you want to backup
# 2. select the admin database
#> use admin
# 3. create an user with the built-in role "backup"
#> db.createUser({ user: "backupuser", pwd: "12345", roles: ["backup"]})
# 4. edit this script with the backup user credentials

MONGO_USER="backupuser"
MONGO_PASS="12345"

MONGO_HOST="127.0.0.1"
MONGO_PORT="27017"
MONGODUMP_PATH="/usr/bin/mongodump"
MONGOCLIENT_PATH="/usr/bin/mongo"
BACKUPS_DIR="/root/mongobackups"

mkdir -p "${BACKUPS_DIR}"

dbs=`$MONGOCLIENT_PATH --username $MONGO_USER --password $MONGO_PASS --authenticationDatabase admin --host $MONGO_HOST:$MONGO_PORT --eval "db.getMongo().getDBNames()" | grep '"' | tr -d '",' | tr -d ']' | tr -d '['`
echo $dbs
TIMESTAMP=`date +%F-%H%M`
mkdir -p "${BACKUPS_DIR}/backup_${TIMESTAMP}"
for db in $dbs; do
    echo "database backup $db at $TIMESTAMP"
    $MONGODUMP_PATH --username $MONGO_USER --password $MONGO_PASS --authenticationDatabase admin --host $MONGO_HOST:$MONGO_PORT --db $db --out "${BACKUPS_DIR}/backup_${TIMESTAMP}"
done
tar -czvf "${BACKUPS_DIR}/backup_${TIMESTAMP}.tar.gz" "${BACKUPS_DIR}/backup_${TIMESTAMP}"
rm -fr "${BACKUPS_DIR}/backup_${TIMESTAMP}"

#rotate
find ${BACKUPS_DIR} -type f -mtime +14 -name '*.gz' -execdir rm -- '{}' \;
