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
  use_command 'ssh' "$@";
}

function use_command() {
  command="$1";
  shift;
  command="${command} ${NODE} ${@}";
  add_debug "Running command: ${command}";
  OUTPUT=`$command`;
  add_info "$OUTPUT";
}

NODE=`hostname -a`;
function parse_arguments() {
  while [[ $# > 0 ]]; do
    case "${1,,}" in
    -l|--no-label)
      NOLABEL=true;
      shift;
      ;;
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
    -s|--silent)
      VERBOSE=false;
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
           -l|--no-label     Supress output being labelled with node
           -n|--node         Node to connect to (default: $NODE)
           -v|--verbose      Add verbosity
           -s|--silent       Less verbose
           -d|--debug        Show debug info
           --help            This screen
           --                Everything after this will be passed to the command

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
        $PROG listnodes | xargs -I {} ssh {} nodetool compactionstats -H
        $PROG nodetool -v -- compactionstats -H
        $PROG shell -v -- nodetool compactionstats -H
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