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
  [[ $VERBOSE ]] && echo -n "Waiting for node to start...";
  until STAT=`nodetool -h $NODE statusbinary 2>&1` && [ "$STAT"  == "running" ]; do
    [[ $VERBOSE ]] && echo -n ".";
    sleep 1;
  done
  [[ $VERBOSE ]] && echo "";
}

function cassandra_listkeyspaces() {
  get_keyspaces;
  for KEYSPACE in "${KEYSPACES[@]}"; do
    if [[ ! " ${PARAMS[@]} " =~ " ${KEYSPACE} " ]]; then
      echo $KEYSPACE;
    fi
  done
}