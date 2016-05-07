#!/bin/bash


trap "rm -f /tmp/all-hosts1" 0 1 2 5 15  
trap "rm -f /tmp/all-hosts2" 0 1 2 5 15  
trap "rm -f /tmp/alive-hosts" 0 1 2 5 15  
trap "rm -f /tmp/all-hosts" 0 1 2 5 15  


#find all hosts
nmap -p22 -n --host-timeout 30 172.24.30.0/24 | sed "s/Nmap.*for/***/g" | grep -v "STATE" | grep -v "Host is" | grep -A 1 "\*\*\*" | tr -d "\n" | sed -e "s/22\/tcp//g" -e "s/ssh/ssh\n/g" > /tmp/all-hosts1
#find v2
nmap -n -sP 172.24.30.* | grep "report for" | awk '{print $(NF)}' > /tmp/alive-hosts
cat /tmp/alive-hosts | xargs nmap -n -p22 |  sed "s/Nmap.*for/***/g" | grep -v "STATE" | grep -v "Host is" | grep -A 1 "\*\*\*" | tr -d "\n" | sed -e "s/22\/tcp//g" -e "s/ssh/ssh\n/g" > /tmp/all-hosts2

#combine
cat /tmp/all-hosts1 /tmp/all-hosts2 | sort | uniq > /tmp/all-hosts

#distr detect
for i in `cat /tmp/all-hosts | grep open | awk '{ print $2}'`; do echo -n " "$i" "; timeout 10 ssh -o StrictHostKeyChecking=no -q -o UserKnownHostsFile=/dev/null -o "BatchMode yes" $i hostname ; echo ""; done  > /tmp/ip-and-hostname




