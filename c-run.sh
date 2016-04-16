#!/usr/bin/env bash
function add_debug() {
  [[ $DEBUG ]] && [[ $1 ]] && echo "$1";
}

# Include
include () {
  if [[ ! $SOURCE_DIR ]]; then
    if [[ -L "$BASH_SOURCE" ]]; then
      SOURCE_ME=$(readlink -f $BASH_SOURCE);
    else
      SOURCE_ME=$BASH_SOURCE;
    fi
    SOURCE_DIR="${SOURCE_ME%/*}";
    if [[ ! -d "$SOURCE_DIR" ]]; then SOURCE_DIR="$PWD"; fi
  fi

  for f in ${SOURCE_DIR}/lib/${1}.inc.sh; do
    add_debug "Including ${f}...";
    . $f;
  done
  #. "${SOURCE_DIR}/lib/${1}.inc.sh"
}
include 'common';
include 'commands/*';

parse_arguments "$@";
run_command;

exit 0;