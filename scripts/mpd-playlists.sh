#!/bin/bash
#
# kozunak.sh - kozunak.org radio sheduler by afx

# Usage: kozunak.sh <subdir>

#SETTINGS
radiodir="/srv/sftp/radio"                                              #location of the music parent dir
mpdconf="/usr/local/etc/musicpd.conf"                                   #location of mpd.conf
alwaysrestart=0                                                         #debug purpouses

################################################

#BOOT
prefix="kozunak.sh: [`date "+%H:%M"`]"
if [ ! -d $radiodir/$1 ] || [ "$1" == "" ] ; then
    echo "$prefix no such playlist $1"
    exit
fi

if [ ! -x $mpdconf ] ; then
    echo "cant find musicpd.conf!"
    exit
fi

hour=`date +%H`
if [ "$hour" = "06" ] || [ $alwaysrestart == 1 ]; then
    echo "$prefix server restart"
    musicpd --kill
    sleep 2
    rm -f /var/run/mpd/database
    #mpd --create-db $mpdconf
    musicpd $mpdconf
fi

#FIX
IFS='
'
for i in 1 2
do

#SCAN FILES
find "$radiodir/$1/" -depth 1 -name "*.flac" | while read flac ; do
    tmp1flac_a=`metaflac --show-tag=Artist "$flac"`
    tmp2flac_a=${tmp1flac_a:7}
    tmp1flac_n=`metaflac --show-tag=Title "$flac"`
    tmp2flac_n=${tmp1flac_n:6}
    baseflac=$(basename "$flac")
    dirflac=$(dirname "$flac")
    newflac=$(echo "$tmp2flac_a - $tmp2flac_n.flac" | tr ' ' '_' | tr '?' '_' | tr '/' '_' | tr -d '#' | tr -d '\n')
    if [ "$tmp2flac_a" == "" ] || [ "$tmp2flac_n" == "" ] ; then
        if [ "${baseflac:0:2}" == "__" ] ; then
        newflac=$(echo "$baseflac" | tr ' ' '_' | tr '?' '_' | tr '/' '_')
        else
        newflac=$(echo "__$baseflac" | tr ' ' '_' | tr '?' '_' | tr '/' '_')
        fi
    fi
    if [ "$baseflac" != "$newflac" ] ; then
        echo "$prefix found $baseflac -> $newflac"
        mv "$flac" "$dirflac/$newflac"
    fi
done
find "$radiodir/$1/" -depth 1 -name "*.mp3" | while read mp3 ; do
    tmpmp3_a=`id3info "$mp3" | grep -i '^=== TPE1 ' | sed 's/^=== TPE1.*: //'`
    if [ "$tmpmp3_a" == "" ] ; then
        tmpmp3_a=`id3v2 -l "$mp3" | grep -i '^TP1 ' | sed 's/^TP1.*: //'`
    fi
    tmpmp3_n=`id3info "$mp3" | grep -i '^=== TIT2 ' | sed 's/^=== TIT2.*: //'`
    if [ "$tmpmp3_n" == "" ] ; then
        tmpmp3_n=`id3v2 -l "$mp3" | grep -i '^TT2 ' | sed 's/^TT2.*: //'`
    fi
    basemp3=$(basename "$mp3")
    dirmp3=$(dirname "$mp3")
    newmp3=$(echo "$tmpmp3_a - $tmpmp3_n.mp3" | tr ' ' '_' | tr '?' '_' | tr '/' '_' | tr -d '#' | tr -d '\n')
    if [ "$tmpmp3_a" == "" ] || [ "$tmpmp3_n" == "" ] ; then
        if [ "${basemp3:0:2}" == "__" ] ; then
        newmp3=$(echo "$basemp3" | tr ' ' '_' | tr '?' '_' | tr '/' '_')
        else
        newmp3=$(echo "__$basemp3" | tr ' ' '_' | tr '?' '_' | tr '/' '_')
        fi
    fi
    if [ "$basemp3" != "$newmp3" ] ; then
        echo "$prefix found $basemp3 -> $newmp3"
        mv "$mp3" "$dirmp3/$newmp3"
    fi
done
done
unset IFS

#INIT MPD
musicdir=`awk '/^music_directory/ {print $2}' $mpdconf | cut -d '"' -f2`
crnt=`mpc -f %file% | head -n 1`
find $musicdir/* -not -name "$crnt" -exec rm {} +
mpc --no-status crop

#IMPORT IN MPD
count=0
find "$radiodir/$1/" -depth 1 -name "*" >  /tmp/kozunak.temp
while read fle ; do
    bsfile=$(basename "$fle")
    if [ "$bsfile" = "$crnt" ] ; then
        continue
    fi
    ln -s "$fle" "$musicdir/$bsfile"
    chown nobody:ftpsrv "$musicdir/$bsfile"
    chmod g+w "$musicdir/$bsfile"
    let "count+=1"
done < /tmp/kozunak.temp
mpc --no-status --wait update
sleep 20
mpc ls | mpc add
mpc --no-status random on
mpc --no-status repeat on
if [ "$hour" = "06" ] || [ $alwaysrestart == 1 ]; then
    mpc --no-status play
else
    mpc --no-status next
    mpc --no-status next
    sleep 2
    mpc --no-status del 1
    rm "$musicdir/$crnt"
fi

#CHANGE BACKGROUND
#rnd=`/root/scripts/devrandom 1 4`

#ln -fs /usr/local/www/nginx/purple$rnd.jpg /usr/local/www/nginx/purple.jpg
