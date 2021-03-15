#!/bin/bash

function psax {
 pid=$*
 for pid in $*
   do
     procpid=/proc/$pid
     if [[ -e $procpid/environ && -e $procpid/stat ]]; then
     
      Time=`awk -v ticks="$(getconf CLK_TCK)" '{print strftime ("%M:%S", ($14+$15)/ticks)}' $procpid/stat`

      Locked=`grep VmFlags $procpid/smaps | grep lo`

      Stats=`awk '{ printf $3; \
      if ($19<0) {printf "<" } else if ($19>0) {printf "N"}; \
      if ($6 == $1) {printf "s"}; \
      if ($20>1) {printf "l"}}' $procpid/stat; \
      [[ -n $Locked ]] && printf "L"; \
      awk '{ if ($8!=-1) { printf "+" }}' $procpid/stat`

      Cmdline=`awk '{ print $1 }' $procpid/cmdline | sed 's/\x0/ /g'`
      [[ -z $Cmdline ]] && Cmdline=`strings -s' ' $procpid/stat | awk '{ printf $2 }' | sed 's/(/[/; s/)/]/'`

      qq=`ls -l $procpid/fd/ | grep -E '\/dev\/tty|pts' | cut -d\/ -f3,4 | uniq`
      Tty=`awk '{ if ($7 == 0) {printf "?"} else { printf "'"$qq"'" }}' $procpid/stat`

    fi
    printf  '%7d %-7s %-12s %s %-10s\n' "$pid" "$Tty" "$Stats" "$Time" "$Cmdline"
  done
}
ALLPIDS=`ls /proc | grep -P ^[0-9] | sort -n | xargs`
printf  '%7s %-7s %-12s %s %-10s\n' "PID" "TTY" "STAT" "TIME" "COMMAND"
psax $ALLPIDS
