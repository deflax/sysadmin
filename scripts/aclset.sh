#!/bin/bash

# afx acl setup

### vars

watchdir="/srv/test"
domainadmin="afx"
password="CHANGEME"

###

#init
controlfile="control.txt"
passfile="password.txt"
aclset="";
acldel="";
old_IFS=$IFS      # save the field separator
IFS=$'\n'     # new field separator, the end of line
exec > /tmp/afxacl.log 2>&1

mlocate --database=/tmp/afxacl.db $controlfile > /tmp/afxacl.set.1.tmp
mlocate --database=/tmp/afxacl.db $passfile > /tmp/afxacl.del.1.tmp
updatedb --database-root=$watchdir --output /tmp/afxacl.db -l 0
mlocate --database=/tmp/afxacl.db $controlfile > /tmp/afxacl.set.2.tmp
mlocate --database=/tmp/afxacl.db $passfile > /tmp/afxacl.del.2.tmp

setlist=`diff /tmp/afxacl.set.1.tmp /tmp/afxacl.set.2.tmp`
aclset=`echo "$setlist" | grep '>'`
dellist=`diff /tmp/afxacl.del.1.tmp /tmp/afxacl.del.2.tmp`
acldel=`echo "$dellist" | grep '>'`

#del
if [ -n "$acldel" ]
then
        while read dline;
        do
                curcontroldel=`echo "$dline" | cut -c 3-`;
                echo "unlocking $curcontroldel"
                ccut=`expr ${#passfile} + 1`
                cdir=`echo "$curcontroldel" | rev | cut -c $ccut- | rev`
                echo ""
                if [ -d "$cdir" ];
                then
                        if grep -q $password "$curcontroldel";
                        then
                                echo "password accepted"
                                chattr -i "$cdir/$controlfile"
                                rm "$cdir/$controlfile"
                                setfacl -R --remove-all "$cdir"
                                chmod 770 "$cdir"
                                echo ""
                                echo "current permissions:"
                                getfacl "$cdir"
                                rm "$curcontroldel"
                        else
                                echo "invalid password!"
                                rm "$curcontroldel"
                        fi
                else
                        echo "warning: whole dir was deleted"
                fi
                echo ""
                echo ""
        done < <(echo "$acldel")
fi

# set
if [ -n "$aclset" ]
then
        while read cline;
        do
                curcontrolset=`echo "$cline" | cut -c 3-`;
                echo "setting up acl from $curcontrolset"
                ccuser=`stat -c "%U" "$curcontrolset"`
                if [ "$ccuser" != "$domainadmin" ];
                then
                        echo "$ccuser is not a valid admin!"
                        rm $curcontrolset
                        continue;
                fi

                echo ""
                ccut=`expr ${#controlfile} + 1`
                cdir=`echo "$curcontrolset" | rev | cut -c $ccut- | rev`
                chmod 700 "$cdir"
                for uline in $(cat "$curcontrolset")
                do
                        echo "add user $uline ..."
                        setfacl -R -n -m u:$uline:rwx "$cdir"
                done
                echo "add admin $domainadmin ..."
                setfacl -R -n -m u:$domainadmin:rwx "$cdir"
                setfacl -R -n -m m::rwx "$cdir"

                chattr +i "$curcontrolset"
                echo ""
                echo "current permissions:"
                getfacl "$cdir"
                echo ""
                echo ""
        done < <(echo "$aclset")

fi

IFS=$old_IFS     # restore default field separator

if [ -s /tmp/afxacl.log ];
then
        mutt -s "setacl.sh notice" mailbox@server.com < /tmp/afxacl.log
fi

#cleantmp
rm /tmp/afxacl.set*
rm /tmp/afxacl.del*

