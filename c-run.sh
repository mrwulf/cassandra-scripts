#!/usr/bin/env bash

# Setup
OPTIND=1;
COMMAND="";
INTRO=true;
NODE=`hostname -a`;

# Colors
CR=`echo -ne '\033[31m'`
CG=`echo -ne '\033[32m'`
CY=`echo -ne '\033[33m'`
BO=`echo -ne '\033[1m'`
CS=`echo -ne '\033[0m'`

# Include
include () {
  if [[ ! $DIR ]]; then
    DIR="${BASH_SOURCE%/*}";
    if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
  fi

  . "${DIR}/lib/${1}.inc.sh"
}
include 'common';

parsearguments;

include 'commands';
case "$COMMAND" in
  '')
    help;
    ;;
  start)
    start;
    ;;
  stop)
    stop;
    ;;
  restart)
    stop;
    start;
    wait;
    ;;
  wait)
    wait;
    ;;
  *)
    help "Unknown command requested: ${CG}${COMMAND}${CS}.";
    ;;
esac

exit 0;
