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

function use_nodetool() {
  OUTPUT=`nodetool -h $NODE $1`;
  add_info "$OUTPUT";
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
        listkeyspaces   Show keyspaces (exclude those listed after --)
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

  function_exists "cassandra_$COMMAND" && (cassandra_$COMMAND || true) && return;

  function_exists "$COMMAND" && ($COMMAND || true) && return;

  help "Unknown command requested: ${CG}${COMMAND}${CS}.";
}