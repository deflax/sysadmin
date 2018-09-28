#!/bin/bash 

## Example .config/rclone/rclone.conf:
#[pcloud]
#type = pcloud
#token = {"access_token":"0000","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"}

#[remotecrypto]
#type = crypt
#remote = pcloud:/encbackup/
#filename_encryption = off
#directory_name_encryption = false
#password = 0000

#find the full backups and rsync them to remote host
SOURCE=(
    "/srv/nfs-backup/warrior/dump"
    "/srv/nfs-backup/lexx/dump"
)

ENCSRC="/srv/nfs-backup/latest-hardlink"

###
human_print(){
while read B dummy; do
  [ $B -lt 1024 ] && echo ${B} B && break
  KB=$(((B+512)/1024))
  [ $KB -lt 1024 ] && echo ${KB} KB && break
  MB=$(((KB+512)/1024))
  [ $MB -lt 1024 ] && echo ${MB} MB && break
  GB=$(((MB+512)/1024))
  [ $GB -lt 1024 ] && echo ${GB} GB && break
  echo $(((GB+512)/1024)) TB
done
}

mkdir $ENCSRC

for srcpath in "${SOURCE[@]}"
do
    vmids=()

    if [ "$(ls -A $srcpath)" ]; then
        echo "[ok] $srcpath"
        cd $srcpath
    else
        echo "[skip] $srcpath" 
        echo ""
        continue
    fi

    host=`echo $srcpath | rev | cut -d'/' -f 2 | rev`
    #mkdir "$ENCSRC/$host"

    vmids+=`ls -1d *.lzo 2> /dev/null | cut -d "-" -f3 | sort | uniq`
    vmids+=`ls -1d *..gz 2> /dev/null | cut -d "-" -f3 | sort | uniq`
    for vmid in $vmids
    do
        last=`ls -1rt $srcpath | grep -E ".lzo$|.gz$" | grep -E "vzdump.*-$vmid-" | tail -1`
        size=`stat -c %s $last | human_print`
        echo "VM $vmid last backup is $last ($size)"
        ln $srcpath/$last $ENCSRC/$host-$last
        echo "$ENCSRC/$host-$last" >> /tmp/reclist.txt
    done
    echo ""
done
cat /tmp/reclist.txt | while read file
do
    du "$file"
done | awk '{i+=$1} END {print "Total bytes: " i / 1048576 " GB"}'

#cloud sync
rclone -v -P sync $ENCSRC remotecrypto:/

#cleanup
rm /tmp/reclist.txt
rm -fr $ENCSRC
