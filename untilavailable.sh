#!/bin/bash

# Setup
OPTIND=1;
HOST="";

function help() {
  echo "$0 [-h|--host HOST] [-v|--verbose] [-1|--one] [--help]";
}

while [[ $# > 0 ]]; do
  case "$1" in
    -h|--host)
      HOST="-h $2";
      shift 2;
      ;;
    -v|--verbose)
      VERBOSE=true;
      shift 1;
      ;;
    -1|--one)
      ONEONLY=true;
      shift 1;
      ;;
    --help)
      help;
      exit 0;
      ;;
  esac
done

until STAT=`nodetool $HOST statusbinary 2>&1` && [ "$STAT"  == "running" ]; do 
  [[ $VERBOSE ]] && echo "Not Available..."; 
  [[ $ONEONLY ]] && exit 1;
  sleep 2; 
done

[[ $VERBOSE ]] && echo "Available!";
exit 0;
