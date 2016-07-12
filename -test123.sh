#!/bin/sh
# Перенести в другую ветку
M_HOST='localhost'
M_USER='redmine'
M_DB='redmine_default'
M_PASS='a1_5i2gt2t12nd24124'
M_PARAMSTR="-h ${M_HOST} -u${M_USER} -p${M_PASS} -B $M_DB"

    for i in `echo "select users.id , groups_users.group_id  from users LEFT  JOIN groups_users  ON  users.id = groups_users.user_id" | mysql ${M_PARAMSTR}| tr -d "|" | grep NULL | cut -f 1`; do 
	BADUSER=`echo  "select  group_id  from groups_users where group_id=$i" |  mysql ${M_PARAMSTR}| grep -c -v id `
	    if [ "$BADUSER" = "0" ]; then
		if  [ "$i" -ne "1" ] && [ "$i" -ne "2" ]  ; then
		GROUPTEST=`echo  "select  login  from users where id=$i" |  mysql ${M_PARAMSTR}| grep  -v login`
		    if [ -n  "$GROUPTEST" ]; then
			echo ======
			echo ID--USER
			echo "$i = $GROUPTEST"
			echo ===
			echo ID--Projects 
			    for MEMBERS in `echo  "select id,user_id,project_id from members where user_id=$i" |  mysql ${M_PARAMSTR} | grep -v id | cut -f 3`; do
				echo $MEMBERS:- ` echo  "select name  from projects where id=$MEMBERS" | mysql ${M_PARAMSTR}| grep -v name`   
			    done
			echo ===
			echo "Enter GroupID for $GROUPTEST"
			read GROUP
			    if [ -n  "$GROUP" ]; then
				echo ""
				echo ========================================
				echo ""
				echo "group = Group.find(:first, :conditions => "id = $GROUP")"
				echo "user=User.find($i)"
				echo "group.users << user"
				echo "group.save"
				echo ""
				echo ========================================
				echo ""
			    fi
		    fi
		fi
	    fi
    done
