#!/bin/sh

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

function help() {
  PROG=$(basename $0);
  ERR_MSG="$*"
  [[ $ERR_MSG ]] && echo -e "\n ${CR} ERROR: ${CS} *** $ERR_MSG ***"

  cat << USAGE
Usage: $PROG
       <command>         Command to run
       -n|--node         Node to execute on (default: $NODE)
       --help            This screen
       -v|--verbose      Add verbosity

Commands:
    start      Start the node
    stop       Stop the node cleanly
    restart    Restarts the node and waits until it's running to return
    wait       Wait until the node is up and running

USAGE
  exit 1;
}

function setcommand() {
  if [[ $COMMAND ]]; then
    help "Only one command may be run at a time. Already running ${CG}${COMMAND}{$CS} when ${CG}${$1}${CS} requested.";
  fi

  COMMAND="${1}"; 
}

function start() {
  useshell sudo service cassandra start;
}

function stop() {
  usenodetool flush;
  usenodetool drain;
  useshell sudo service cassandra stop;
}

function usenodetool() {
  OUTPUT=`nodetool -h $NODE $1`;
  [[ $VERBOSE ]] && [[ $OUTPUT ]] && echo $OUTPUT;
}

function useshell() {
  OUTPUT=`ssh $NODE "$@"`;
  [[ $VERBOSE ]] && echo $OUTPUT;
}

function wait() {
  [[ $VERBOSE ]] && echo -n "Waiting for node to start...";
  until STAT=`nodetool -h $NODE statusbinary 2>&1` && [ "$STAT"  == "running" ]; do
    [[ $VERBOSE ]] && echo -n ".";
    sleep 2;
  done  
  [[ $VERBOSE ]] && echo "";
}

while [[ $# > 0 ]]; do
  case "$1" in
  -n|--node)
    NODE=$2;
    shift 2;
    ;;
  -v|--verbose)
    VERBOSE=true;
    shift;
    ;;
  --help)
    help;
    ;;
  *)
    setcommand $1;
    shift;
    ;;
  esac
done


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
