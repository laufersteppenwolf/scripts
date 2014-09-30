#!/bin/bash

# Script to manage dropbox on servers
# Can also be used as an init.d script

 
DROPBOX_USERS="laufersteppenwolf"
DAEMON=$(ls /home/$DROPBOX_USERS/.dropbox-dist/dropbox-lnx.x86_64-*/dropbox)
 
start() {
   echo "Starting dropbox..."
   for dbuser in $DROPBOX_USERS; do
      HOMEDIR=$(getent passwd $dbuser | cut -d: -f6)
      if [ -x $DAEMON ]; then
         HOME="$HOMEDIR" start-stop-daemon -b -o -c $dbuser -S -u $dbuser -x $DAEMON
      fi
   done
}
 
stop() {
   echo "Stopping dropbox..."
   for dbuser in $DROPBOX_USERS; do
      HOMEDIR=$(getent passwd $dbuser | cut -d: -f6)
      if [ -x $DAEMON ]; then
         start-stop-daemon -o -c $dbuser -K -u $dbuser -x $DAEMON
      fi
   done
}
 
status() {
   for dbuser in $DROPBOX_USERS; do
   dbpid=$(pgrep -u $dbuser dropbox)
   if [[ -z $dbpid ]] ; then
      echo "dropboxd for USER $dbuser: not running."
   else
      echo "dropboxd for USER $dbuser: running (pid $dbpid)"
   fi
   done
}
 
case "$1" in
   start)
      start
      sleep 1
      status
      ;;
 
   stop)
      stop
      sleep 3
      status
      ;;
 
   restart)
      stop
      sleep 3
      start
      sleep 1
      status
      ;;
 
   status)
      status
      ;;
 
   *)
      echo "Usage: /path/to/script/dropbox.sh {start|stop|restart|status}"
      start
      exit 0
 
esac
 
exit 0

