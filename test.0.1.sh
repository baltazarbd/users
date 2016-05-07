#! /bin/sh

#Global
user_key_list=`ls /root/ |grep key |awk -F. '{print $1  " User  off " }'|sort`
server_list=`cat /root/serverlist|awk  '{print $1,$2, "off " }'|sort`
#Dialog
DIALOG=${DIALOG=dialog}  #переменая для вызова диалога 
tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/test$$  #тмп файлик для диалога
trap "rm -f $tempfile" 0 1 2 5 15  #очищаем после себя врменный файлик если получили завершающий сигнал 0 1 2 5 15 

#Функции 
#######  Выбираем юзера 
dialog_choose_user () {
    $DIALOG --backtitle "Choose user" \
	    --title "Choose list " --clear \
	    --radiolist "Choose user:" 30 60 30  ${user_key_list}       2> $tempfile
    retval=$?
    choice_user=`cat $tempfile`
    case $retval in
	1)
	    ./$0 ;;
	255)
	    echo "Нажата клавиша ESC." exit;;
    esac
}

### Выбираем группу 
dialog_choose_group () {
    $DIALOG --backtitle "Choose group" \
	    --title "Choose group list " --clear \
	    --radiolist " Groups " 20 61 3 \
		"Litota" "Литота разрабы" off \
		"FB-Adm" "Наши админы " ON \
		"Other" "Кто-то хз кто" off   2> $tempfile
    retval=$?
    choice_group=`cat $tempfile`
    case $retval in
	1)
	    ./$0;;
	255)
	    echo "Нажата клавиша ESC." exit;;
    esac
}


### Выбираем сервера 
dialog_choose_server () {
    $DIALOG --backtitle "Choose servers" \
	--title "Servers list " --clear \
	--checklist "Choose servers:" 30 60 30  ${server_list}       2> $tempfile
    retval=$?
    choice_server=`cat $tempfile`
    case $retval in
	1)
	    ./$0 ;;
	255)
	    echo "Нажата клавиша ESC." exit ;;
    esac
}

##	Добовляем ключик 
add_ssh_key () {
	    if [ "$check_sshdir_in_homedir_on_server" = "1" ]; then
		usersshkey=`cat /root/$choice_user.key`
		ssh $server_ip "echo $usersshkey > /home/$choice_user/.ssh/authorized_keys"
		ssh  $server_ip "chown $choice_user:$choice_user /home/$choice_user/.ssh/authorized_keys"
		echo "Add key $choice_user  on $server_ip"
	    else
		ssh $server_ip "mkdir  /home/$choice_user/.ssh/"
		ssh $server_ip "chown $choice_user:$choice_user  /home/$choice_user/.ssh/"
		ssh $server_ip "echo $usersshkey > /home/$choice_user/.ssh/authorized_keys"
		ssh  $server_ip "chown $choice_user:$choice_user  /home/$choice_user/.ssh/authorized_keys"
		echo "Add key $choice_user  on $server_ip"
	    fi 
}




#Main screen 
$DIALOG --backtitle "Choose action" \
	--title "Choose action " --clear \
	--radiolist " action " 20 61 10 \
	    "1" "Добавить пользователя" ON \
	    "2" "Удалить пользователя" off \
	    "3" "Обновить ssh ключ" off \
	    "4" "Заблокировать пользователя" off \
	    "5" "Разблокировать пользователя" off \
	    "6" "Посмотреть судо права для группы " off \
	    "7" "Дать права судо группе " off \
	    "8" "Удалить права судо  для группы " off   2> $tempfile

    retval=$?
    choice_action=`cat $tempfile`
    case $retval in
	1)
	    ./$0;;
	255)
	    echo "Нажата клавиша ESC." exit;;
    esac


case $choice_action in 

    1)
	dialog_choose_user
	dialog_choose_group
	dialog_choose_server

##	Добовляем пользователя
        for server_ip in ${choice_server} ; do

##		Проверяем существует ли пользователь и добовляем 
	    check_user_on_server=`ssh  $server_ip cat /etc/passwd |grep -c $choice_user `
	    if [ "$check_user_on_server" = "0" ]; then
		ssh $server_ip "useradd -m -U $choice_user"
		echo "Add $choice_user on $server_ip"
	    else
		echo "User $choice_user  already exists  on $server_ip"
	    fi

##		Проверяем существуетли группа и добовляем

	    check_group_on_server=`ssh  $server_ip cat /etc/group |grep -c $choice_group `
	    if [ "$check_group_on_server" = "1" ]; then
		ssh $server_ip "usermod -g $choice_group $choice_user"
		echo "Add $choice_user in $choice_group on $server_ip"
	    else
		ssh $server_ip "groupadd $choice_group"
		echo "Add group $choice_group on $server_ip"
		ssh $server_ip "usermod -g $choice_group $choice_user"
		echo "Add $choice_user in $choice_group on $server_ip"
		echo "Warning $choice_user  doesn't have sudo privileges on $server_ip"
	    fi

##		Добовляем ключик 

	    check_sshdir_in_homedir_on_server=`ssh  $server_ip ls -la /home/$choice_user/ |grep -c ".ssh" `
	    add_ssh_key 
	done 
    ;;

    2)
	dialog_choose_user
	dialog_choose_server

	for server_ip in ${choice_server} ; do
		ssh $server_ip "userdel -rf $choice_user "
		ssh $server_ip "groupdel  $choice_user "
		ssh $server_ip "rm -rf  /home/$choice_user/"
		echo "Delete $choice_user on  $server_ip"
	done 
    ;;

    3)
	dialog_choose_user
	dialog_choose_server

	for server_ip in ${choice_server} ; do
	check_sshdir_in_homedir_on_server=`ssh  $server_ip ls -la /home/$choice_user/ |grep -c ".ssh" `
	add_ssh_key  
	done
    ;;

    4)
	dialog_choose_user
	dialog_choose_server

	for server_ip in ${choice_server} ; do
		ssh $server_ip "usermod -L $choice_user "
		ssh  $server_ip "rm /home/$choice_user/.ssh/authorized_keys"
		echo " User $choice_user is block "
	done
    ;;

    5)
	dialog_choose_user
	dialog_choose_server

	for server_ip in ${choice_server} ; do
		ssh $server_ip "usermod -U $choice_user "
		add_ssh_key  
		echo " User $choice_user is unblock "
	done
    ;;


esac 
