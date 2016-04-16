#!/bin/sh

# Setup
OPTIND=1;
set -e;

# Colors
CR=`echo -ne '\033[31m'`;
CG=`echo -ne '\033[32m'`;
CY=`echo -ne '\033[33m'`;
BO=`echo -ne '\033[1m'`;
CS=`echo -ne '\033[0m'`;

TOIGNORE=();
COMMAND="";

while [[ $# > 0 ]]; do

  case "$1" in
    -x)
      TOIGNORE+=($2);
      shift 2;
      ;;
    --exclude=*)
      TOIGNORE+=("${1#*=}");
      shift 1;
      ;;

    -d|--debug)
      DEBUG=true;
      shift 1;
      ;;

    -v|--verbose)
      VERBOSE=true;
      shift 1;
      ;;

    --)
      shift;
      COMMAND="${COMMAND} $@";
      break;
      ;;

    *)
      COMMAND="${COMMAND} $1";
      shift 1;
      ;;
  esac
done

if [[ $COMMAND == "" ]]; then
  COMMAND='echo $KEYSPACE';
fi

# Get Keyspaces
KEYSPACES=();

for KEYSPACE in $(cqlsh `hostname -a` -e "DESC KEYSPACES" | perl -pe 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g' | sed '/^$/d'); do
  KEYSPACES+=( "$KEYSPACE" );
done

# Sort for sanity
IFS=$'\n';
SORTED=($(sort <<<"${KEYSPACES[*]}"));
unset IFS;

for KEYSPACE in "${SORTED[@]}"; do
    if [[ ! " ${TOIGNORE[@]} " =~ " ${KEYSPACE} " ]]; then
      [[ $VERBOSE ]] && echo "${CG}Keyspace $KEYSPACE: ${CS}";

      [[ $DEBUG ]] && echo "Running command: ${COMMAND}.";
      eval "$COMMAND" || true;
    fi
done
