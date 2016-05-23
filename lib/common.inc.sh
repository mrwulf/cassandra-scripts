# Colors
CR='\033[31m'; # Red
CG='\033[32m'; # Green
CY='\033[33m'; # Yellow
BO='\033[1m';  # Bold
CS='\033[0m';  # Clear Formatting

# Function:   add_info
# Parameters: $1   -> Text to print
#             ($2) -> Optional: force    - always print (overrides VERBOSE)
#                               noprefix - don't prefix node (same as NOLABEL)
#                               inline   - remove newlines
function add_info() {
  if [[ $1 ]] && ( [[ $VERBOSE ]] || [[ "$2" =~ force ]] ); then
    prefix="${NODE}:\t";
    if [[ "$2" =~ noprefix ]] || [[ $NOLABEL ]]; then
      prefix='';
    fi

    IFS=$'\n';
    for line in $1; do
      if [[ "$2" =~ inline ]]; then
        echo -n -e "${prefix}${line}";
      else
        echo -e "${prefix}${line}";
      fi
    done
    unset IFS;
  fi
}

function use_nodetool() {
  use_command 'nodetool -h' "$@";
}

function use_shell() {
  use_command 'ssh' "${@}";
}

function use_command() {
  command="$1";
  shift;
  command="${command} ${NODE} ${@}";
  add_debug "Running command: ${command}";
  OUTPUT=`$command`;
  add_info "${OUTPUT}";
}

NODE=`hostname -a`;
function parse_arguments() {
  while [[ $# > 0 ]]; do
    add_debug "Found argument: ${1}";
    case "${1,,}" in
    -l|--no-label)
      add_debug "Turning off labels.";
      NOLABEL=true;
      shift;
      ;;
    -n|--node)
      add_debug "Will connect to node ${2}.";
      NODE=$2;
      shift 2;
      ;;
    --)
      shift;
      add_debug "The rest will be piped on as... $*";
      PARAMS=("$@");
      break;
      ;;
    -v|--verbose)
      add_debug "Turning on verbose.";
      VERBOSE=true;
      shift;
      ;;
    -s|--silent)
      add_debug "Turning off verbose.";
      VERBOSE=false;
      shift;
      ;;
    -d|--debug)
      add_debug "Turning on debug.";
      DEBUG=true;
      shift;
      ;;
    --help)
      help;
      ;;
    *)
      add_debug "Setting command to run: ${1}";
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
           -l|--no-label     Supress output being labelled with node
           -n|--node         Node to connect to (default: $NODE)
           -v|--verbose      Add verbosity
           -s|--silent       Less verbose
           -d|--debug        Show debug info
           --help            This screen
           --                Everything after this will be passed to the command (with one level of quotes removed)

    Commands:
      List:
        allstatus         Show the status of all nodes
        listnodes         Show nodes in this cluster
        listkeyspaces     Show keyspaces (exclude those listed after --)
      One Node:
        start             Start a node
        stop              Stop a node cleanly
        restart           Restarts a node and waits until it's running again
        wait              Wait until a node is up and running
      All Nodes:
        allrestart        Sequentially restart all of the nodes in this cluster
        allpuppetdeploy   Sequentially enable and run the puppet agent
        allpuppetdisable  Disable puppet agent on all nodes (specify message after --)
        nodetool          Run nodetool on all nodes (specify command after --)
        shell             Run a shell command on all nodes (specify command after --)

    Examples:
        $PROG rollingrestart
        $PROG listnodes | xargs -I {} ssh {} nodetool compactionstats -H
        $PROG nodetool -- compactionstats -H
        $PROG shell -- nodetool compactionstats -H
USAGE

  exit 1;
}

COMMAND="";
function set_command() {
  [[ $COMMAND ]] && help "Only one command may be run at a time. Already running ${CG}${COMMAND}${CS} when ${CG}${1}${CS} requested.";

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