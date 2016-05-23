NODES=();
function get_nodes() {
  # Uses global NODES variable
  NODES=();

  # Get this node
  NODE=`cqlsh $NODE -e 'SELECT rpc_address FROM system.local' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`;
  NODES+=( "$NODE" );
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
    add_info "${dnsname%.}" 'force'; # The %. at the end trims the trailing dot
  done
}

function cassandra_allrestart() {
  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Restarting Node: ${NODE} ${CS}" 'noprefix';
    cassandra_restart;
  done
}

function cassandra_allpuppetdeploy() {
  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Running on node: ${NODE} ${CS}" 'noprefix';
    use_nodetool flush;
    use_shell sudo puppet agent --enable;
    use_shell sudo puppet agent --test;
    cassandra_wait;
  done
}

function cassandra_allpuppetdisable() {
  [[ ! $PARAMS ]] && help "You must supply a disable message!";

  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Running on node: ${NODE} ${CS}" 'noprefix';
    use_shell sudo puppet agent --disable "'${PARAMS[@]}'";
    use_shell sudo killall puppet;
  done
}

function cassandra_allstatus() {
  get_nodes;
  for NODE in "${NODES[@]}"; do
    if cassandra_checkstatus; then
      add_info "Node ${NODE} is UP." 'noprefix|force';
    else
      add_info "Node ${NODE} is DOWN." 'noprefix|force';
    fi
  done
}

function cassandra_nodetool() {
  VERBOSE=true;
  _cassandra_command 'nodetool';
}

function cassandra_shell() {
  VERBOSE=true;
  _cassandra_command 'shell';
}

function _cassandra_command() {
  [[ ! $PARAMS ]] && help "You must supply a command to run!";

  get_nodes;
  for NODE in "${NODES[@]}"; do
    add_info "${CG}Node: ${NODE} ${CS}" 'noprefix';
    use_$1 "${PARAMS[@]}";
  done
}