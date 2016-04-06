#!/bin/bash

until STAT=`nodetool statusbinary 2>&1` && [ "$STAT"  == "running" ]; do 
  echo "Not Available..."; 
  sleep 2; 
done

echo "Available!";
