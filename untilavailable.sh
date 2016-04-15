#!/bin/bash

# Setup
OPTIND=1;
HOST="";

function help() {
  cat <<USAGE
Usage: $0
       -h | --host HOST   The host to check
       -v | --verbose     Show text
       -1 | --one         One and done - don't wait
       --help             This message

USAGE
  exit 1;
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
