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

    -d)
    DEBUG=true;
    shift 1;
    ;;
    --debug)
    DEBUG=true;
    shift 1;
    ;;

    *) 
    COMMAND="${COMMAND} $1";
    shift 1;
    ;;
  esac 
done

for KEYSPACE in $(cqlsh `hostname -a` -e "DESC KEYSPACES" | perl -pe 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g' | sed '/^$/d'); do
    if [[ ! " ${TOIGNORE[@]} " =~ " ${KEYSPACE} " ]]; then
      echo "${CG}Keyspace $KEYSPACE: ${CS}"; 
   
      [[ $DEBUG ]] && echo "Running command: ${COMMAND}.";
      eval $COMMAND || true;
    fi 
done

