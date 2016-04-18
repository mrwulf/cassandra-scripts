NODES=();
function get_nodes() {
  # Uses global NODES variable
  NODES=();

  # Get this node
  NODES+=( $(cqlsh $NODE -e 'SELECT rpc_address FROM system.local' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}') );
  add_debug "Connected to: ${NODES[@]}";

  # Get the other nodes
  for PEER in $(cqlsh $NODE -e 'SELECT peer FROM system.peers' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'); do
    add_debug "Found peer: ${PEER}";
    NODES+=( "$PEER" );
  done

  # Sort to make it cleaner
  IFS=$'\n';
  SORTEDNODES=($(sort -V <<<"${NODES[*]}"));
  unset IFS;

  NODES=("${SORTEDNODES[@]}");
  unset SORTEDNODES;
}

function cassandra_listnodes() {
  get_nodes;
  for NODE in "${NODES[@]}"; do
    dnsname=`dig -x $NODE +short`;
    add_info "${NODE}\t --> ${dnsname%.}" 'noprefix|force';
  done
}

function cassandra_rollingrestart() {
  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Restarting Node: ${NODE} ${CS}" 'noprefix';
    cassandra_restart;
  done
}

function cassandra_nodetool() {
  _cassandra_command 'nodetool';
}

function cassandra_shell() {
  _cassandra_command 'shell';
}

function _cassandra_command() {
  [[ ! $PARAMS ]] && help "You must supply a command to run";

  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Node: ${NODE} ${CS}" 'noprefix';
    use_$1 "${PARAMS[@]}";
  done
}