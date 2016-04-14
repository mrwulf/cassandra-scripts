#!/bin/sh

# Setup
OPTIND=1;
COMMAND="";
INTRO=true;

# Colors
CR=`echo -ne '\033[31m'`
CG=`echo -ne '\033[32m'`
CY=`echo -ne '\033[33m'`
BO=`echo -ne '\033[1m'`
CS=`echo -ne '\033[0m'`

function help() {
  PROG=$(basename $0);
  cat << USAGE
Usage: $PROG
       <command>         Commands to pass to nodetool
       -i | --intro      Don't introduce each node
       -v | --verbose    Add some text
       --help            This screen

Examples:
    $PROG compactionstats -H
    $PROG | xargs -I {} ssh {} uptime
USAGE
  exit 1;
}

while [[ $# > 0 ]]; do
  case "$1" in
  -i|--intro)
    INTRO=false;
    shift;
    ;;
  -v|--verbose)
    VERBOSE=true;
    shift;
    ;;  
  --help)
    help;
    ;;
  --)
    shift;
    COMMAND="${COMMAND} $@";
    break;
    ;;
  *)
    COMMAND="${COMMAND} $1";
    shift;
    ;;  
  esac
done

NODES=()

# Get this node
NODES+=( $(cqlsh `hostname -a` -e 'SELECT rpc_address FROM system.local' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}') );
[[ $VERBOSE ]] && echo "Running on: ${NODES[@]}";

# Get the other nodes
for PEER in $(cqlsh `hostname -a` -e 'SELECT peer FROM system.peers' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'); do
  [[ $VERBOSE ]] && echo "Found peer: ${PEER}";
  NODES+=( "$PEER" );
done

# Sort to make it cleaner
IFS=$'\n';
SORTEDNODES=($(sort -V <<<"${NODES[*]}"));
unset IFS;

for NODE in "${SORTEDNODES[@]}"; do
    if [[ $COMMAND ]]; then
      [[ $INTRO ]] && echo -e "${CG}Node: ${NODE} ${CS}";

      nodetool -h $NODE $COMMAND; 
    else
      echo $NODE;
    fi
done
