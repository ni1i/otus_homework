#!/bin/bash

if
sudo find /var/log -name log_stat.sh -exec {} \; > log_stat.txt && mailx root@localhost < log_stat.txt && rm log_stat.txt access.log
then
exit 0
else 
echo "Error."
fi