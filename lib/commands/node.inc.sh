KEYSPACES=();
function get_keyspaces() {
  # Uses global KEYSPACES variable
  KEYSPACES=();

  for KEYSPACE in $(cqlsh $NODE -e "DESC KEYSPACES" | perl -pe 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g' | sed '/^$/d'); do
    KEYSPACES+=( "$KEYSPACE" );
  done

  # Sort for sanity
  IFS=$'\n';
  SORTEDKEYSPACES=($(sort -V <<<"${KEYSPACES[*]}"));
  unset IFS;

  KEYSPACES=("${SORTEDKEYSPACES[@]}");
  unset SORTEDKEYSPACES;
}

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
  add_info "Waiting for node to be active..." 'inline';
  until cassandra_checkstatus; do
    add_info "." 'noprefix|inline';
    sleep 1;
  done
  add_info "." 'noprefix';
}

function cassandra_checkstatus() {
  if stat=`nodetool -h $NODE statusbinary 2>&1` && [[ "$stat" == "running" ]]; then
    add_debug "${NODE} is running.";
    return 0;
  fi

  add_debug "${NODE} is not running. Status=${stat}."
  return 1;
}

function cassandra_safestop() {
  get_nodes;
  target="$NODE";
  add_debug "Trying to safely stop ${target}.";

  use_nodetool flush;

  use_nodetool disablebinary;

  other_node_down=false;
  for NODE in "${NODES[@]}"; do
    if [[ "$NODE" != "$target" ]]; then
      if ! cassandra_checkstatus; then
        # Other node is down, re-enable this node
        add_debug "Other node (${NODE}) is down, so we can't stop now.";
        NODE="$target";
        use_nodetool enablebinary;
        other_node_down=true;
        break;
      fi
    fi
  done

  NODE="$target";

  if [[ "$other_node_down" == false ]]; then
    add_debug "No other nodes are down, so we can fully stop now.";
    use_nodetool drain;
    use_shell sudo service cassandra stop;
  fi
}

function cassandra_listkeyspaces() {
  get_keyspaces;
  for KEYSPACE in "${KEYSPACES[@]}"; do
    if [[ ! " ${PARAMS[@]} " =~ " ${KEYSPACE} " ]]; then
      add_info "$KEYSPACE" 'noprefix|force';
    fi
  done
}