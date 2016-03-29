#!/bin/sh

# Colors
CR=`echo -ne '\033[31m'`
CG=`echo -ne '\033[32m'`
CY=`echo -ne '\033[33m'`
BO=`echo -ne '\033[1m'`
CS=`echo -ne '\033[0m'`


NODES=()

# Get this node
NODES+=( $(cqlsh `hostname -a` -e 'SELECT rpc_address FROM system.local' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}') );

# Get the other nodes
for PEER in $(cqlsh `hostname -a` -e 'SELECT peer FROM system.peers' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'); do
  NODES+=( "$PEER" );
done

# Sort to make it cleaner
IFS=$'\n';
SORTEDNODES=($(sort <<<"${NODES[*]}"));
unset IFS;

for H in "${SORTEDNODES[@]}"; do
    echo -e "\n${CG}Host: ${H} ${CS}"; 
    nodetool -h $H "$@"; 
done
