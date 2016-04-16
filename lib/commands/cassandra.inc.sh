function cassandra_restart() {
  cassandra_stop;
  cassandra_start;
  cassandra_wait;
}

function cassandra_start() {
  use_shell sudo service cassandra start;
}

function cassandra_stop() {
  use_nodetool flush;
  use_nodetool drain;
  use_shell sudo service cassandra stop;
}

function cassandra_wait() {
  [[ $VERBOSE ]] && echo -n "Waiting for node to start...";
  until STAT=`nodetool -h $NODE statusbinary 2>&1` && [ "$STAT"  == "running" ]; do
    [[ $VERBOSE ]] && echo -n ".";
    sleep 1;
  done
  [[ $VERBOSE ]] && echo "";
}

function cassandra_listnodes() {
  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info_inline `dig -x $NODE +short`;
    add_info_inline " -- ";
    echo $NODE;
  done
}

function cassandra_rollingrestart() {
  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Restarting Node: ${NODE} ${CS}";
    cassandra_restart;
  done
}

function cassandra_nodetool() {
  [[ ! $PARAMS ]] && help "You must supply a command for nodetool to run";

  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Node: ${NODE} ${CS}";
    use_nodetool "${PARAMS[@]}";
  done
}

function cassandra_shell() {
  [[ ! $PARAMS ]] && help "You must supply a command to run";

  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Node: ${NODE} ${CS}";
    add_debug "Running command: ${PARAMS[@]}";
    use_shell "${PARAMS[@]}";
  done
}

function cassandra_listkeyspaces() {
  get_keyspaces;
  for KEYSPACE in "${KEYSPACES[@]}"; do
    if [[ ! " ${PARAMS[@]} " =~ " ${KEYSPACE} " ]]; then
      echo $KEYSPACE;
    fi
  done
}