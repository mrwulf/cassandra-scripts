function start() {
  useshell sudo service cassandra start;
}

function stop() {
  usenodetool flush;
  usenodetool drain;
  useshell sudo service cassandra stop;
}

function wait() {
  [[ $VERBOSE ]] && echo -n "Waiting for node to start...";
  until STAT=`nodetool -h $NODE statusbinary 2>&1` && [ "$STAT"  == "running" ]; do
    [[ $VERBOSE ]] && echo -n ".";
    sleep 1;
  done
  [[ $VERBOSE ]] && echo "";
}