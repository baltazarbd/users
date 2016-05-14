#!/bin/bash 
IFS=$'\n'

trap "rm -f /tmp/all-hosts1 /tmp/all-hosts2 /tmp/alive-hosts /tmp/all-hosts /tmp/ip-and-hostname" 0 1 2 5 15  

#find all hosts
nmap -p22 -n --host-timeout 30 172.24.0.0/16 | sed "s/Nmap.*for/***/g" | grep -v "STATE" | grep -v "Host is" | grep -A 1 "\*\*\*" | tr -d "\n" | sed -e "s/22\/tcp//g" -e "s/ssh/ssh\n/g" > /tmp/all-hosts1

#find v2
nmap -n -sP 172.24.*.* | grep "report for" | awk '{print $(NF)}' > /tmp/alive-hosts
cat /tmp/alive-hosts | xargs nmap -n -p22 |  sed "s/Nmap.*for/***/g" | grep -v "STATE" | grep -v "Host is" | grep -A 1 "\*\*\*" | tr -d "\n" | sed -e "s/22\/tcp//g" -e "s/ssh/ssh\n/g" > /tmp/all-hosts2

#combine
cat /tmp/all-hosts1 /tmp/all-hosts2 | sort | uniq > /tmp/all-hosts

#distr detect

for i in `cat /tmp/all-hosts | grep open | awk '{ print $2}'| sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n`; do 
    echo -n " "$i" "; timeout 10 ssh -o StrictHostKeyChecking=no -q -o UserKnownHostsFile=/dev/null -o "BatchMode yes" $i hostname; 
done  > /tmp/ip-and-hostname

for ip in `cat /tmp/ip-and-hostname`; do
    ip_for_sqlite=`echo $ip| cut -f 2 -d " "`
    host_for_sqlite=`echo $ip| cut -f 3 -d " "`
    only_ip=`echo $ip |awk '{print $1}'`
    sqlite_ip=`echo \'$only_ip\'`
    ip_in_db=`sqlite3 users.db "select ip from  hosts where ip = $sqlite_ip;" |grep -c $only_ip`;
    
    if [ "$ip_in_db" = "0" ]; then
	sqlite3 users.db "insert into hosts (ip,hostname) values ('$ip_for_sqlite','$host_for_sqlite');"
    fi
done

for del_old_ip in `sqlite3 users.db "select ip from  hosts;"`; do 
    current_ip=`cat /tmp/all-hosts |grep -c $del_old_ip`
    
    if [ "$current_ip" = "0" ]; then
	sqlite3 users.db "delete from  hosts where ip= '$del_old_ip'"
    fi

done





