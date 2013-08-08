#!/bin/bash

PORT=$((13000 + $UID))
HOST=http://localhost:$PORT
TYPE=$1
shift
QUERY=$@

# Check the status of the server
curl -o /dev/null -s $HOST/status
ACTIVE=$?

if [ "$ACTIVE" != "0" ]; then
  source ~/.rvm/scripts/rvm
  bundle exec pincernad -e production -p $PORT -d
fi

curl -X GET -s --data-urlencode "q=$QUERY" http://localhost:$PORT/$TYPE