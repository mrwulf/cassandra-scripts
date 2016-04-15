
function usenodetool() {
  OUTPUT=`nodetool -h $NODE $1`;
  [[ $VERBOSE ]] && [[ $OUTPUT ]] && echo $OUTPUT;
}

function useshell() {
  OUTPUT=`ssh $NODE "$@"`;
  [[ $VERBOSE ]] && echo $OUTPUT;
}

function setcommand() {
  if [[ $COMMAND ]]; then
    help "Only one command may be run at a time. Already running ${CG}${COMMAND}{$CS} when ${CG}${$1}${CS} requested.";
  fi

  COMMAND="${1}";
}

function parsearguments() {
  while [[ $# > 0 ]]; do
    case "$1" in
    -n|--node)
      NODE=$2;
      shift 2;
      ;;
    -v|--verbose)
      VERBOSE=true;
      shift;
      ;;
    --help)
      help;
      ;;
    *)
      setcommand $1;
      shift;
      ;;
    esac
  done
}

function help() {
  PROG=$(basename $0);
  ERR_MSG="$*"
  [[ $ERR_MSG ]] && echo -e "\n ${CR} ERROR: ${CS} *** $ERR_MSG ***"

  cat <<-USAGE
    Usage: $PROG
           <command>         Command to run
           -n|--node         Node to execute on (default: $NODE)
           --help            This screen
           -v|--verbose      Add verbosity

    Commands:
        start      Start the node
        stop       Stop the node cleanly
        restart    Restarts the node and waits until it's running
        wait       Wait until the node is up and running

USAGE
  exit 1;
}