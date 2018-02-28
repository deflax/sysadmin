#!/bin/bash

cd /srv/backup
dirsplit -L -s 400G /srv/backup/encfs/
cp /srv/backup/vol_1/.encfs /srv/backup/vol_2/
