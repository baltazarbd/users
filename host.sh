#!/bin/bash

#find all hosts
nmap -p22 -n --host-timeout 30 172.25.0.0/16 | sed "s/Nmap.*for/***/g" | grep -v "STATE" | grep -v "Host is" | grep -A 1 "\*\*\*" | tr -d "\n" | sed -e "s/22\/tcp//g" -e "s/ssh/ssh\n/g" > /tmp/all-hosts1

#find v2
nmap -n -sP 172.25.*.* | grep "report for" | awk '{print $(NF)}' > /tmp/alive-hosts
cat /tmp/alive-hosts | xargs nmap -n -p22 |  sed "s/Nmap.*for/***/g" | grep -v "STATE" | grep -v "Host is" | grep -A 1 "\*\*\*" | tr -d "\n" | sed -e "s/22\/tcp//g" -e "s/ssh/ssh\n/g" > /tmp/all-hosts2

#combine
cat /tmp/all-hosts1 /tmp/all-hosts2 | sort | uniq > /tmp/all-hosts

#distr detect
for i in `cat /tmp/all-hosts | grep open | awk '{ print $2}'`; do echo -n "*** "$i" "; timeout 10 ssh -o StrictHostKeyChecking=no -q -o UserKnownHostsFile=/dev/null -o "BatchMode yes" $i cat /proc/version ; echo ""; done  > /tmp/distr-detect

#get gentoo hosts
cat /tmp/distr-detect | grep -i gentoo | awk '{print $2}' > /tmp/gentoo-hosts

#get debian hosts
cat /tmp/distr-detect | grep -i debian | awk '{print $2}' > /tmp/debian-hosts