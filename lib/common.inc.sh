# Colors
CR=`echo -ne '\033[31m'`
CG=`echo -ne '\033[32m'`
CY=`echo -ne '\033[33m'`
BO=`echo -ne '\033[1m'`
CS=`echo -ne '\033[0m'`

function add_info() {
  [[ $VERBOSE ]] && [[ $1 ]] && echo "$1";
}

function add_info_inline() {
  [[ $VERBOSE ]] && [[ $1 ]] && echo -n -e "$1";
}

function add_debug() {
  [[ $DEBUG ]] && [[ $1 ]] && echo "$1";
}

function use_nodetool() {
  OUTPUT=`nodetool -h $NODE $1`;
  add_info "$OUTPUT";
}

NODES=();
function get_nodes() {
  # Uses global NODES variable
  NODES=();

  # Get this node
  NODES+=( $(cqlsh `hostname -a` -e 'SELECT rpc_address FROM system.local' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}') );
  add_debug "Running on: ${NODES[@]}";

  # Get the other nodes
  for PEER in $(cqlsh `hostname -a` -e 'SELECT peer FROM system.peers' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'); do
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

function use_shell() {
  OUTPUT=`ssh $NODE "$@"`;
  add_info $OUTPUT;
}

NODE=`hostname -a`;
function parse_arguments() {
  while [[ $# > 0 ]]; do
    case "${1,,}" in
    -n|--node)
      NODE=$2;
      shift 2;
      ;;
    --)
      shift;
      PARAMS=("$@");
      break;
      ;;
    -v|--verbose)
      VERBOSE=true;
      shift;
      ;;
    -d|--debug)
      DEBUG=true;
      shift;
      ;;
    --help)
      help;
      ;;
    *)
      set_command $1;
      shift;
      ;;
    esac
  done
}

function help() {
  PROG=$(basename $0);
  ERR_MSG="$*"
  [[ $ERR_MSG ]] && echo -e "\n ${CR} ERROR: ${CS} *** $ERR_MSG ***"

  cat <<USAGE
    Usage: $PROG
           <command>         Command to run
           -n|--node         Node to execute on (default: $NODE)
           --help            This screen
           -v|--verbose      Add verbosity
           -d|--debug        Show debug info
           --                Everything else will be passed to the command

    Commands:
        start           Start a node
        stop            Stop a node cleanly
        restart         Restarts a node and waits until it's running again
        wait            Wait until a node is up and running
        listnodes       Show nodes in this cluster
        rollingrestart  Sequentially restart all of the nodes in this cluster
        nodetool        Run nodetool on all nodes (specify command after --)
        shell           Run a shell command on all nodes (specify command after --)

    Examples:
        $PROG rollingrestart
        $PROG listnodes | xargs -I {} ssh {} uptime
        $PROG nodetool -v -- compactionstats -H
        $PROG shell -v -- hostname -a
USAGE

  exit 1;
}

COMMAND="";
function set_command() {
  [[ $COMMAND ]] && help "Only one command may be run at a time. Already running ${CG}${COMMAND}{$CS} when ${CG}${$1}${CS} requested.";

  COMMAND="${1,,}";
}

function function_exists() {
    declare -f -F $1 > /dev/null;
    return $?;
}

function run_command() {
  [[ ! $COMMAND ]] && help;

  function_exists "cassandra_$COMMAND" && cassandra_$COMMAND && return;

  function_exists "$COMMAND" && $COMMAND && return;

  help "Unknown command requested: ${CG}${COMMAND}${CS}.";
}