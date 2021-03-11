#!/usr/bin/env bash
lockfile=/tmpfile

if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
    trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
       # What to do
        /var/log/sendmail.sh ${lockfile}
   rm -f "$lockfile"
   trap - INT TERM EXIT
else
   echo "Failed to acquire lockfile: $lockfile."
   echo "Held by $(cat $lockfile)"
fi

if
    sudo find /var/log -name log_stat.sh -exec {} \; > log_stat.txt && mailx root@localhost < log_stat.txt && rm log_stat.txt access.log
then
    exit 0
   else 
echo "Error."
fi

X=10
Y=10

echo "Request generated:" && date && echo "Log started:" && cat access.log | awk '{print $4$5}' | head -n 1
echo " *** *** *** "

echo $X "most requests from:" && cat access.log | awk -F" " '{print $1}' | sort | uniq -c | sort -rn | head -n $X | awk '{print $1 " requests from " $2}'
echo " *** *** *** "

echo $Y "most requested URLs:" && cat access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -n $Y | awk '{print $2 " requested " $1 " times. "}' | column -t
echo " *** *** *** "

echo "HTTP errors:" && cat access.log | awk '{print $9}' | grep ^4 | sort | uniq -c | sort -rn | awk '{print $2 " - " $1 " times."}' && cat access.log | awk '{print $9}' | grep ^5 | sort | uniq -c | sort -rn | awk '{print $2 " - " $1 " times."}'
echo " *** *** *** "

echo "HTTP statuses:" && cat access.log | awk '{print $9}'| grep -v "-" | sort | uniq -c | sort -rn | awk '{print $2 " - " $1 " times."}'