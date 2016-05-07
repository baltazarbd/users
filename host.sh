#!/bin/bash 
IFS=$'\n'

trap "rm -f /tmp/all-hosts1 /tmp/all-hosts2 /tmp/alive-hosts /tmp/all-hosts" 0 1 2 5 15  

#find all hosts
nmap -p22 -n --host-timeout 30 172.24.30.0/24 | sed "s/Nmap.*for/***/g" | grep -v "STATE" | grep -v "Host is" | grep -A 1 "\*\*\*" | tr -d "\n" | sed -e "s/22\/tcp//g" -e "s/ssh/ssh\n/g" > /tmp/all-hosts1
#find v2
nmap -n -sP 172.24.30.* | grep "report for" | awk '{print $(NF)}' > /tmp/alive-hosts
cat /tmp/alive-hosts | xargs nmap -n -p22 |  sed "s/Nmap.*for/***/g" | grep -v "STATE" | grep -v "Host is" | grep -A 1 "\*\*\*" | tr -d "\n" | sed -e "s/22\/tcp//g" -e "s/ssh/ssh\n/g" > /tmp/all-hosts2
#combine
cat /tmp/all-hosts1 /tmp/all-hosts2 | sort | uniq > /tmp/all-hosts

#distr detect

for i in `cat /tmp/all-hosts | grep open | awk '{ print $2}'`; do 
    echo -n " "$i" "; timeout 10 ssh -o StrictHostKeyChecking=no -q -o UserKnownHostsFile=/dev/null -o "BatchMode yes" $i hostname ; echo ""; 
done  > /tmp/ip-and-hostname




for ip in `cat /tmp/ip-and-hostname`; do
    ip_for_sqlite=`echo $ip| cut -f 2 -d " "`
    host_for_sqlite=`echo $ip| cut -f 3 -d " "`
    ip_in_db=`sqlite3 users.db "select ip from  hosts;"  |  grep -c $ip `;
    if [ "$ip_in_db" = "0" ]; then
    sqlite3 users.db "insert into hosts (ip,hostname) values ('$ip_for_sqlite','$host_for_sqlite');"
    fi
done


#for ip in `iptables-save |grep WHITELIST |cut -f 4 -d " " | sed "s/\/32//g"  | grep -v tcp`; do
#    NGINXIP=`cat /etc/nginx/access/* /etc/nginx/conf.d/iplist-access.include |grep -v '#'  |  grep -c $i `;
#    if [ "$NGINXIP" = "0" ]; then
#    iptables -D $IPCHAIN -s $i $IPTABLCMD
#    fi
#done




