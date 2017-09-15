#!/bin/sh
# Time to wait before removing mails from the Junk folder (Default: 7 days) Set 0 to turn off.
junk_max_hours=$((24*2))
# Time to wait before removing mails from the Trash folder (Default: 30 days) Set 0 to turn off.
trash_max_hours=$((24*10))
for domain in /var/vmail/*
do
  if [ -d "$domain" ]
  then
    for user in $domain/*
    do
      if [ "$junk_max_hours" -gt "0" ]
      then
        if [ -d "$user/Maildir/.Junk" ]
        then
          tmpreaper -m $junk_max_hours $user/Maildir/.Junk/{cur,new}
        fi
      fi
      if [ "$trash_max_hours" -gt "0" ]
      then
        if [ -d "$user/Maildir/.Trash" ]
        then
          tmpreaper -m $trash_max_hours $user/Maildir/.Trash/{cur,new}
        fi
      fi
    done
  fi
done

