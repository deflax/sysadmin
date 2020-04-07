#!/bin/bash

# acl setup

### vars

watchdir="/srv/share"
domainadmin="admin"
password="bangovasil"

###

#init
controlfile="control.txt"
passfile="delete.txt"
aclset="";
acldel="";
old_IFS=$IFS      # save the field separator
IFS=$'\n'     # new field separator, the end of line
exec >> /var/log/afxacl.log 2>&1

mlocate --database=/var/tmp/afxacl.db $controlfile > /var/tmp/afxacl.set.1.tmp
mlocate --database=/var/tmp/afxacl.db $passfile > /var/tmp/afxacl.del.1.tmp
updatedb --database-root=$watchdir --output /var/tmp/afxacl.db -l 0
mlocate --database=/var/tmp/afxacl.db $controlfile > /var/tmp/afxacl.set.2.tmp
mlocate --database=/var/tmp/afxacl.db $passfile > /var/tmp/afxacl.del.2.tmp

setlist=`diff /var/tmp/afxacl.set.1.tmp /var/tmp/afxacl.set.2.tmp`
aclset=`echo "$setlist" | grep '>'`
dellist=`diff /var/tmp/afxacl.del.1.tmp /var/tmp/afxacl.del.2.tmp`
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
                updatedb --database-root=$watchdir --output /var/tmp/afxacl.db -l 0
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

#if [ -s /var/log/afxacl.log ];
#then
#        mutt -s "ACL" user@mail.com < /var/tmp/afxacl.log
#fi

#cleantmp
rm /var/tmp/afxacl.set*
rm /var/tmp/afxacl.del*
