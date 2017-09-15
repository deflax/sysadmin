#!/bin/bash                                                                                                                                                          [40/1057]

#find the full backups and rsync them to remote host

SOURCE=(
    "/srv/nfs-backup/host1/dump"
    "/srv/nfs-backup/host2/dump"
)
HOST=1.2.3.4

ENCSRC="/srv/nfs-backup/latest-hardlink"
ENCTARGET="/tmp/latest-encfs"
ENCCONFIG="/etc/scripts/.encfs6.xml"

ENCPASS=my_strong_password

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

rm /tmp/reclist.txt 2> /dev/null
mkdir $ENCSRC
mkdir $ENCTARGET

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
    mkdir "$ENCSRC/$host"

    vmids+=`ls -1d *.vma.lzo 2> /dev/null | cut -d "-" -f3 | sort | uniq`
    vmids+=`ls -1d *.vma.gz 2> /dev/null | cut -d "-" -f3 | sort | uniq`
    for vmid in $vmids
    do
        last=`ls -1rt $srcpath | grep -E ".lzo$|.gz$" | grep -E "vzdump.*-$vmid-" | tail -1`
        size=`stat -c %s $last | human_print`
        echo "VM $vmid last backup is $last ($size)"
        ln $srcpath/$last $ENCSRC/$host/
        echo "$srcpath/$last" >> /tmp/reclist.txt
    done
    echo ""
done

cat /tmp/reclist.txt | while read file
do
    du "$file"
done | awk '{i+=$1} END {print "Total bytes: " i / 1048576 " GB"}'

#reverse encfs
echo $ENCPASS | ENCFS6_CONFIG=$ENCCONFIG encfs --reverse --idle=60 -o ro --stdinpass $ENCSRC $ENCTARGET

#sync
#rsync -vap -e 'ssh -p 2222' --files-from=/tmp/reclist.txt / backup@$HOST:/srv/backup
rsync -vap --copy-links -e 'ssh -p 2222' $ENCTARGET/ backup@$HOST:/srv/backup/weekly-encfs
rsync -vap -e 'ssh -p 2222' $ENCCONFIG backup@$HOST:/srv/backup/weekly-encfs/.encfs6.xml

#cleanup
fusermount -u $ENCTARGET
rmdir $ENCTARGET
rm -fr $ENCSRC

