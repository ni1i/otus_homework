#!/bin/bash

function psax {
 PID=$*
 for PID in $*
   do
     procpid=/proc/$PID
     if [[ -e $procpid/environ && -e $procpid/stat ]]; then

      Locked=`grep VmFlags $procpid/smaps | grep lo`

      tmp=`ls -l $procpid/fd/ | grep -E '\/dev\/tty|pts' | cut -d\/ -f3,4 | uniq`
      TTY=`awk '{ if ($7 == 0) {printf "?"} else { printf "'"$tmp"'" }}' $procpid/stat`

      STAT=`awk '{ printf $3; \
      if ($19<0) {printf "<" } else if ($19>0) {printf "N"}; \
      if ($6 == $1) {printf "s"}; \
      if ($20>1) {printf "l"}}' $procpid/stat; \
      [[ -n $Locked ]] && printf "L"; \
      awk '{ if ($8!=-1) { printf "+" }}' $procpid/stat`

      TIME=`awk -v ticks="$(getconf CLK_TCK)" '{print strftime ("%M:%S", ($14+$15)/ticks)}' $procpid/stat`

      COMMAND=`awk '{ print $1 }' $procpid/cmdline | sed 's/\x0/ /g'`
      [[ -z $COMMAND ]] && COMMAND=`strings -s' ' $procpid/stat | awk '{ printf $2 }' | sed 's/(/[/; s/)/]/'`

    fi
    printf  '%7d %-7s %-12s %s %-10s\n' "$PID" "$TTY" "$STAT" "$TIME" "$COMMAND"
  done
}
ALLPIDS=`ls /proc | grep -P ^[0-9] | sort -n | xargs`
printf  '%7s %-7s %-12s %s %-10s\n' "PID" "TTY" "STAT" "TIME" "COMMAND"
psax $ALLPIDS
