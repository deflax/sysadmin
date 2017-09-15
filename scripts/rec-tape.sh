#!/bin/bash

# afx tape backup from proxmox dumps

TAPE=/dev/nst0
SOURCE=(
    "/srv/proxmox/1/dump"
    "/srv/proxmox/2/dump"
)

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

echo "--- tape backup by afx ---"
rm /tmp/reclist.txt 2> /dev/null
#mt -f $TAPE defcompression 1

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

    vmids+=`ls -1d *.vma.lzo 2> /dev/null | cut -d "-" -f3 | sort | uniq`
    vmids+=`ls -1d *.vma.gz 2> /dev/null | cut -d "-" -f3 | sort | uniq`
    for vmid in $vmids
    do
        last=`ls -1rt $srcpath | grep -E ".lzo$|.gz$" | grep -E "vzdump.*-$vmid-" | tail -1`
        size=`stat -c %s $last | human_print`
        echo "VM $vmid last backup is $last ($size)"
        echo "$srcpath/$last" >> /tmp/reclist.txt
    done
    echo ""
done

cat /tmp/reclist.txt | while read file
do
    du "$file"
done | awk '{i+=$1} END {print "Total bytes: " i / 1048576 " GB"}'

read -r -p "Do you want record this list? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "[`date +'%Y-%m-%d %T'`]: << REWIND"
    mt -f $TAPE rewind
    echo "[`date +'%Y-%m-%d %T'`]: () REC"
    #tar -cvf - -T /tmp/reclist.txt | dd of=$TAPE bs=2M
    #blocksize 256k (lto-4 default) -b n*512
    tar -b 512 -cvf $TAPE -T /tmp/reclist.txt
    echo ""
    echo "[`date +'%Y-%m-%d %T'`]: [] STOP"
    echo "file list" > /root/tape-`date +'%Y-%m-%d'`.log
    echo "---" >> /root/tape-`date +'%Y-%m-%d'`.log
    cat /tmp/reclist.txt >> /root/tape-`date +'%Y-%m-%d'`.log
    read -n 1 -s -p "Press any key to display smart & tape info and quit..."
    smartctl -a $TAPE
    tapeinfo -f $TAPE 
fi

echo "Bye."
