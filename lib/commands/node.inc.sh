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
  add_info "Waiting for node to start..." 'inline';
  until STAT=`nodetool -h $NODE statusbinary 2>&1` && [ "$STAT"  == "running" ]; do
    add_info "." 'noprefix|inline';
    sleep 1;
  done
  add_info "." 'noprefix';
}

function cassandra_listkeyspaces() {
  get_keyspaces;
  for KEYSPACE in "${KEYSPACES[@]}"; do
    if [[ ! " ${PARAMS[@]} " =~ " ${KEYSPACE} " ]]; then
      add_info "$KEYSPACE" 'noprefix|force';
    fi
  done
}